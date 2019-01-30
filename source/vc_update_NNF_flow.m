function [NNF, nUpdate]= vc_update_NNF_flow(trgPatch, videoFlow, NNF, opt)
%%
% Update the nearest neighbor field for flow synthesis using PatchMatch
% algorithm

%%
% Initialize update index map
NNF.updateInd = false(NNF.uvPix.numUvPix, 1);

% Number of updates from (1) propagation update and (2) random sampling update
nUpdate = zeros(2,1);

for i = 1: opt.numPassPerIter
    
    % Coarse-to-fine random sampling
    [NNF, n] = vc_random_search_flow(trgPatch, videoFlow, NNF, opt);
    nUpdate(2) = nUpdate(2) + n;
    
    % Spatio-temporal propagation
    for iDirect = 1: opt.nPropDir
        [NNF, n] = vc_propagate_flow(trgPatch, videoFlow, NNF, opt, iDirect);
        nUpdate(1) = nUpdate(1) + n;
    end
end

end

%%

% Task: Merge update data

function [NNF, nUpdateTotal] = vc_random_search_flow(trgPatch, videoFlow, NNF, opt)

%%

[imgH, imgW, nCh, nFrame, nFlow] = size(videoFlow);

% Search range
searchRad = [imgH, imgW, nFrame/2, opt.radFlowScale, opt.radFlowRotation];

nUpdateTotal = 0;

numUvPix = NNF.uvPix.numUvPix;
uvPixActiveInd = true(numUvPix, 1);

iter = 1;
while(1)
    iter = iter + 1;
    % Reduce search radius by half
    searchRad = searchRad/2;
    if(searchRad(3) < 1)
        break;
    end
    searchRad(3) = round(max(searchRad(3), 1));
    searchRad(3) = round(searchRad(3));
    % === Prepare uvT candidates ===
    uvTCand = NNF.uvT.data;
    
    % Draw random samples in spatial domain
    randOffsetS = (rand(numUvPix, 2) - 0.5)*diag(searchRad(1:2));
    uvTCand(:,1:2) = bsxfun(@plus, uvTCand(:,1:2), randOffsetS);
    
    % Draw random samples in temporal domain
    randOffsetT = randi([-searchRad(3), searchRad(3)], numUvPix, 1);
    uvTCand(:,3) = uvTCand(:,3) + randOffsetT;
    
    % === Prepare uvFlowTform candidates===
    uvFlowTformCandA = NNF.uvFlowTformA.data;
    
    % Draw random samples in scale and rotation
    % scale
    uvFlowTformCandA(1,:,:) = uvFlowTformCandA(1,:,:) + ...
        (rand(1, 2, numUvPix) - 0.5)*searchRad(4);
    uvFlowTformCandA(1,:,:) = vc_clamp(uvFlowTformCandA(1,:,:), ...
        opt.minFlowScale, opt.maxFlowScale);
    % rotation
    uvFlowTformCandA(2,:,:) = uvFlowTformCandA(2,:,:) + ...
        (rand(1, 2, numUvPix) - 0.5)*searchRad(5);
    
    % === Reject invalid samples ===
    % Check if the souce patch is valid
    uvValidSrcInd = vc_check_valid_uv(uvTCand, NNF.validPix.mask);
    % Check if the cost is already low
    uvValidCostInd = NNF.uvCost > opt.rsThres;
    
    uvValidInd = uvPixActiveInd & uvValidSrcInd & uvValidCostInd;
    
    uvPixActivePos = find(uvValidInd);
    numActPix = size(uvPixActivePos, 2);
    
    if(numActPix~=0)
        % Update
        trgPatchCur      = trgPatch(:,:,:,uvValidInd);
        uvCostDataCur    = NNF.uvCost(uvValidInd);
        uvTCandCur       = uvTCand(uvValidInd, :);
        
        uvPixValidInd = NNF.uvPix.ind(uvValidInd);
        uvPixValidSub = NNF.uvPix.sub(uvValidInd,:);
        
        uvFlowTformCandCurA = uvFlowTformCandA(:,:,uvValidInd);
        
        wPatchCur  = NNF.wPatchST(:,:,:,uvValidInd);
        
        % Grab source patches
        srcPatchCur =  vc_prep_flow_patch(videoFlow, uvTCandCur, NNF.uvSrcRefPos);
        
        % Compute patch matching cost
        [uvCostCand, uvFlowTformCandCurT] = vc_patch_cost_flow(trgPatchCur, srcPatchCur, videoFlow, ...
            uvFlowTformCandCurA, uvPixValidSub, wPatchCur, NNF.uvSrcRefPos, opt);
        
        % Check which one to update
        updateInd = (uvCostCand < uvCostDataCur);
        nUpdate = sum(updateInd);
        
        if(nUpdate~=0)
            uvPixActivePos = uvPixActivePos(updateInd);
            uvPixValidInd  = uvPixValidInd(updateInd);
            
            nUpdateTotal = nUpdateTotal + nUpdate;
            % === Update NNF data ===
            % Update shift
            uvTCandCur = uvTCandCur(updateInd,:);
            NNF.uvT.data(uvPixActivePos, :) = uvTCandCur;
            NNF.uvT.map    = vc_update_uvMap(NNF.uvT.map, uvTCandCur, uvPixValidInd);
            
            % Update cost
            NNF.uvCost(uvPixActivePos) = uvCostCand(updateInd);
            NNF.updateInd(uvPixActivePos)         = 1;
            
            % Update flow transform
            NNF.uvFlowTformA.data(:,:,uvPixActivePos) = uvFlowTformCandCurA(:,:,updateInd);
            NNF.uvFlowTformT.data(:,:,uvPixActivePos) = uvFlowTformCandCurT(:,:,updateInd);
            
            uvFlowTformA = reshape(uvFlowTformCandCurA(:,:,updateInd), [4, nUpdate])';
            uvFlowTformT = reshape(uvFlowTformCandCurT(:,:,updateInd), [4, nUpdate])';
            
            NNF.uvFlowTformA.map = vc_update_uvMap(NNF.uvFlowTformA.map, ...
                uvFlowTformA, uvPixValidInd);
            
            NNF.uvFlowTformT.map = vc_update_uvMap(NNF.uvFlowTformT.map, ...
                uvFlowTformT, uvPixValidInd);
        end
    end
end


end

function [NNF, nUpdateTotal] = vc_propagate_flow(trgPatch, videoFlow, NNF, opt, indDirection)

%%

%%
[imgH, imgW, nCh, nFrame, nFlow] = size(videoFlow);

nUpdateTotal = 0;

% The positions of neighboring pixels
uvPixN = NNF.uvPixN{indDirection};
uvPixActiveInd = uvPixN.validInd;

numUpdatePix = NNF.uvPix.numUvPix;

while(numUpdatePix ~= 0) % While there still active patches for propagation
    
    % Prepare uvPix, uvPixNCur
    uvPix.sub      = NNF.uvPix.sub(uvPixActiveInd, :);
    uvPix.ind      = NNF.uvPix.ind(uvPixActiveInd);
    uvPixNCurIind  = uvPixN.ind(uvPixActiveInd);
    
    trgPatchCur    = trgPatch(:,:,:, uvPixActiveInd);   % Current target patch
    uvCostCur      = NNF.uvCost(uvPixActiveInd);        % Current patch matching cost
    uvPixActivePos = find(uvPixActiveInd);             % Active pixel positions
    
    wPatchCur      =  NNF.wPatchST(:,:,:,uvPixActiveInd);
    
    % Get candidate uvT
    uvTCand = vc_uvMat_from_uvMap(NNF.uvT.map, uvPixNCurIind);
    
    % Get flow transformation parameters
    uvFlowTformA = vc_uvMat_from_uvMap(NNF.uvFlowTformA.map, uvPixNCurIind);
    
    % Generate candidate uvT by propagation
    % JIA-BIN: HOW TO DO PROPAGATION???
    if(indDirection <= 4)
        AinvC = (1./uvFlowTformA(:,1)).*cos(-uvFlowTformA(:,2));
        AinvS = (1./uvFlowTformA(:,1)).*sin(-uvFlowTformA(:,2));
        
        propDirX = opt.propDir(indDirection,1)*AinvC - opt.propDir(indDirection,2)*AinvS;
        propDirY = opt.propDir(indDirection,1)*AinvS + opt.propDir(indDirection,2)*AinvC;
        
        % Apply transformation on propagation direction
        uvTCand(:,1) = uvTCand(:,1) + propDirX;
        uvTCand(:,2) = uvTCand(:,2) + propDirY;
    else
        uvTCand = bsxfun(@plus, uvTCand, single(opt.propDir(indDirection,:)));
    end
    
    % Check if the nearest neighbors are valid source patches
    uvValidSrcInd = vc_check_valid_uv(uvTCand, NNF.validPix.mask);
    
    % Check if the nearest neighbors are already the same as the existing one
    diff = abs(uvTCand - NNF.uvT.data(uvPixActiveInd,:));
    uvValidDistInd = (diff(:,1) >= 1) | (diff(:,2) >= 1) | (diff(:,3) >= 1);
    
    % Number of valid candidates
    uvValidInd = uvValidSrcInd & uvValidDistInd;
    numUvValid = sum(uvValidInd);
    
    % === Check if the candidates are better matches ===
    if(numUvValid > 1)
        
        trgPatchCur    = trgPatchCur(:,:,:, uvValidInd); % Current target patch
        uvCostCur      = uvCostCur(uvValidInd);        % Current patch matching cost
        uvPixUpdatePos = uvPixActivePos(uvValidInd);   % Active pixel positions
        uvTCand        = uvTCand(uvValidInd, :);       % Candidate uvT
        
        uvPixValid.sub = uvPix.sub(uvValidInd,:);
        uvPixValid.ind = uvPix.ind(uvValidInd);
        
        wPatchCur      = wPatchCur(:, :,:, uvValidInd);     % Patch weight
        
        % Prepare uvFlowTformA
        uvFlowTformA = reshape(uvFlowTformA(uvValidInd,:)', [2, 2, numUvValid]);
        
        % Grab source patches
        srcPatchCur =  vc_prep_flow_patch(videoFlow, uvTCand, NNF.uvSrcRefPos);
        
        % Compute patch matching cost
        [uvCostCand, uvFlowTformT] = vc_patch_cost_flow(trgPatchCur, srcPatchCur, videoFlow, ...
            uvFlowTformA, uvPixValid.sub, wPatchCur, NNF.uvSrcRefPos, opt);
        
        % Check which one to update
        updateInd = uvCostCand < uvCostCur;
        
        uvPixUpdatePos = uvPixUpdatePos(updateInd);
        numUpdatePix = size(uvPixUpdatePos, 1);
    else
        numUpdatePix = 0;
    end
    
    % === Update NNF data ===
    if(numUpdatePix ~= 0)
        nUpdateTotal = nUpdateTotal + numUpdatePix;
        
        % === Update NNF data ===
        uvPixValidInd = uvPixValid.ind(updateInd);
        % Shift
        NNF.uvT.data(uvPixUpdatePos, :)     = uvTCand(updateInd, :);
        NNF.uvT.map    = vc_update_uvMap(NNF.uvT.map, ...
            uvTCand(updateInd,:), uvPixValidInd);
        
        % Cost
        NNF.uvCost(uvPixUpdatePos)          = uvCostCand(updateInd);
        NNF.updateInd(uvPixUpdatePos)       = 1;
        
        % flow transform
        uvFlowTformA = uvFlowTformA(:,:,updateInd);
        uvFlowTformT = uvFlowTformT(:,:,updateInd);
        NNF.uvFlowTformA.data(:,:,uvPixUpdatePos) = uvFlowTformA;
        NNF.uvFlowTformT.data(:,:,uvPixUpdatePos) = uvFlowTformT;
        
        uvFlowTformA = reshape(uvFlowTformA, [4, numUpdatePix])';
        uvFlowTformT = reshape(uvFlowTformT, [4, numUpdatePix])';
        
        NNF.uvFlowTformA.map = vc_update_uvMap(NNF.uvFlowTformA.map, ...
            uvFlowTformA, uvPixValidInd);
        
        NNF.uvFlowTformT.map = vc_update_uvMap(NNF.uvFlowTformT.map, ...
            uvFlowTformT, uvPixValidInd);
        
        % === Update uvPixActiveInd ===
        uvPixNextSub = uvPixValid.sub(updateInd,:);
        uvPixNextSub = bsxfun(@plus, uvPixNextSub, opt.propDir(indDirection, :));
        uvPixNextSub(:,3) = vc_clamp(uvPixNextSub(:,3), 1, NNF.nFrame);
        
        uvPixNextInd = sub2ind([NNF.imgH, NNF.imgW, NNF.nFrame], ...
            uvPixNextSub(:,2), uvPixNextSub(:,1), uvPixNextSub(:,3));
        
        updateMap = NNF.uvPix.mask;
        updateMap(uvPixNextInd) = 0;
        uvPixActiveInd = ~updateMap(NNF.uvPix.ind);
        uvPixActiveInd = uvPixActiveInd & uvPixN.validInd;
    end
end

end

