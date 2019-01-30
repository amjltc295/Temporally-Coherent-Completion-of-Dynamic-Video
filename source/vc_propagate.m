function [NNF, nUpdateTotal] = vc_propagate(trgPatch, videoData, videoFlow, NNF, opt, indDirection)

%%

%%
[imgH, imgW, nCh, nFrame] = size(videoData);

nUpdateTotal = 0;

% The positions of neighboring pixels
uvPixN = NNF.uvPixN{indDirection};
uvPixActiveInd = uvPixN.validInd;

numUpdatePix = NNF.uvPix.numUvPix;

% while(iter <= opt.numPropSample || numUpdatePix ~= 0) % While there still active patches for propagation
while(numUpdatePix ~= 0) % While there still active patches for propagation
    
    % Prepare uvPix, uvPixNCur
    uvPix.sub     = NNF.uvPix.sub(uvPixActiveInd, :);
    uvPix.ind     = NNF.uvPix.ind(uvPixActiveInd);
    uvPixNCurIind = uvPixN.ind(uvPixActiveInd);
    
    trgPatchCur   = trgPatch(:,:, uvPixActiveInd);     % Current target patch
    uvCostCur     = NNF.uvCost(uvPixActiveInd);        % Current patch matching cost
    uvPixActivePos = find(uvPixActiveInd);             % Active pixel positions
    
    wPatchCur =  NNF.wPatchST(:,:,:,uvPixActiveInd);
    
    % Get candidate uvT
    uvTCand = vc_uvMat_from_uvMap(NNF.uvT.map, uvPixNCurIind);
    
    % Generate candidate uvT by propagation
    if(opt.useFlowGuidedProp) % Use flow-guided temporal propagation
        if(indDirection <= 4) % Spatial propagation
            uvTCand = bsxfun(@plus, uvTCand, opt.propDir(indDirection,:));
        else                  % Temporal propagation
            uvTCand = vc_flow_guide_prop(uvTCand, videoFlow, opt.propDir(indDirection, 3));
        end
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
    if(numUvValid ~= 0)
        uvPixValid.sub = uvPix.sub(uvValidInd,:);
        uvPixValidind = uvPix.ind(uvValidInd);
        
        trgPatchCur    = trgPatchCur(:,:, uvValidInd); % Current target patch
        uvCostCur      = uvCostCur(uvValidInd);        % Current patch matching cost
        uvPixUpdatePos = uvPixActivePos(uvValidInd);   % Active pixel positions
        uvTCand        = uvTCand(uvValidInd, :);       % Candidate uvT
        wPatchCur      = wPatchCur(:, :,:, uvValidInd);     % Patch weight
        
        % Grab source patches
        srcPatchCur = vc_prep_source_patch(videoData, uvTCand,   NNF.uvSrcRefPos);
        
        % Compute patch matching cost
        [uvCostCand, uvBiasCand] = ...
            vc_patch_cost(trgPatchCur, srcPatchCur, wPatchCur, opt);
        
        % Check which one to update
        updateInd = uvCostCand < uvCostCur;
        
        uvPixUpdatePos = uvPixUpdatePos(updateInd);
        numUpdatePix = size(uvPixUpdatePos, 1);
    else
        numUpdatePix = 0;
    end
    
    % === Update NNF data ===
    if(numUpdatePix ~= 0)
        uvPixValidind = uvPixValidind(updateInd);
        nUpdateTotal = nUpdateTotal + numUpdatePix;
        
        % === Update NNF data ===
        uvTCand = uvTCand(updateInd, :);
        NNF.uvT.data(uvPixUpdatePos, :)     = uvTCand;
        NNF.uvT.map    = vc_update_uvMap(NNF.uvT.map, uvTCand, uvPixValidind);
        NNF.uvCost(uvPixUpdatePos)          = uvCostCand(updateInd);
        NNF.updateInd(uvPixUpdatePos)       = 1;
        if(opt.useBiasCorrection)
            NNF.uvBias(:, uvPixUpdatePos)       = uvBiasCand(:,updateInd);
        end
        
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

