% =========================================================================
% Nearest neighbor field update
% =========================================================================
function [NNF, nUpdate]= vc_update_NNF(trgPatch, videoColor, videoFlow, NNF, isolatedPixInd, opt)
% VC_UPDATE_NNF: Update nearest neighbor field
% Input:
%   - trgPatch:     target patch      - [patchSize*patchSize] x [7] x [numPix]
%   - meanTrgPatch: mean target patch - [1] x [7] x [numPix]
%   - videoData:    video color       - [imgH] x [imgW] x [3] x [nFrame]
%   - videoFlow:    fw/bw flow field  - [imgH] x [imgW] x [2] x [nFrame] x [2]
%   - NNF:          nearest neighbor field
%   - opt:          parameters
% Output:
%   - NNF:          updated nearest neighbor field
%   - nUpdate:      numbers of update for random search, spatial/temproal propagation
% =========================================================================

% Initialize update index map
nUpdate.randSearch   = 0;
nUpdate.propSpatial  = 0;
nUpdate.propTemporal = 0;

initLvlFlag = opt.iLvl == opt.numPyrLvl;

if(~initLvlFlag)
    flowFwInd = 1:2;
    flowBwInd = 3:4;
    videoFlowFw = videoFlow(:,:,flowFwInd,:);
    videoFlowBw = videoFlow(:,:,flowBwInd,:);
end

% =========================================================================
% Coarse-to-fine random search
% =========================================================================
[imgH, imgW, ~, nFrame] = size(videoColor);

% Specify search range
if(initLvlFlag)
    searchRad = [imgW, imgH, nFrame, 0, 0, 0]; % No geometric transformation
    uvActiveInd = true(NNF.trgPix.numPix, 1);
else
    searchRad = [imgW, imgH, nFrame/2, opt.srcTfmRad];
    uvActiveInd = isolatedPixInd;
end

searchRadCur = searchRad;              % Initialize the search radius
searchRangeReduceFactor = 2;           % Factor of coarse to fine search

while(1)
    % Reduce search radius by half
    searchRadCur    = searchRadCur/searchRangeReduceFactor;
    searchRadCur(3) = floor(searchRadCur(3)); % Frame indices are integers
    if(searchRadCur(2) < opt.minSearchRad) % Break when the search range is small enough
        break;
    end
    
    % Randome search
    [srcPosCand, srcTfmGCand, uvCostCand, uvUpdatePos] = ...
        vc_random_search(trgPatch, videoColor, NNF, searchRadCur, uvActiveInd, opt);
    
    if(isempty(uvUpdatePos))
        continue;
    end
    
    % Update NNF
    NNF.srcPos.data(uvUpdatePos, :)  = srcPosCand;
    NNF.srcTfmG.data(uvUpdatePos, :) = srcTfmGCand;
    
    % Update srcPos, srcTfmG maps
    trgPixIndCur = NNF.trgPix.ind(uvUpdatePos);
    
    uvMapIndP = get_uvmap_ind(size(NNF.srcPos.map), trgPixIndCur);
    NNF.srcPos.map(uvMapIndP)  = srcPosCand;
    uvMapIndG = get_uvmap_ind(size(NNF.srcTfmG.map), trgPixIndCur);
    NNF.srcTfmG.map(uvMapIndG) = srcTfmGCand;
    
    % Update matching cost
    NNF.uvCost(uvUpdatePos, :) = uvCostCand;
    uvActiveInd(uvUpdatePos) = 0;
    
    nUpdate.randSearch = nUpdate.randSearch + size(uvUpdatePos, 1);
end

% =========================================================================
% Spatio-temporal propagation
% =========================================================================
for i = 1: opt.numPassPerIter
    % === Temporal propagation: along the direction [0, 0, 1] ===
    frameInc = -1;
    for indFrame = 2:nFrame
        % Temporal propagation
        if(initLvlFlag)
            [srcPosCand, srcTfmGCand, uvCostCand, uvUpdatePos] = ...
                vc_propgate_temporal_init(trgPatch, videoColor, NNF, opt, frameInc, indFrame);
        else
            [srcPosCand, srcTfmGCand, uvCostCand, uvUpdatePos] = ...
                vc_propagate_temporal(trgPatch, videoColor, ...
                videoFlowBw, videoFlowFw, [], NNF, opt, frameInc, indFrame);
        end
        
        % Skip the frame if there is no update
        if(isempty(uvUpdatePos))
            continue;
        end
        
        % Update NNF
        NNF.srcPos.data(uvUpdatePos, :)  = srcPosCand;
        NNF.srcTfmG.data(uvUpdatePos, :) = srcTfmGCand;
        
        % Update srcPos, srcTfmG maps
        trgPixIndCur = NNF.trgPix.ind(uvUpdatePos);
        uvMapIndP = get_uvmap_ind(size(NNF.srcPos.map), trgPixIndCur);
        NNF.srcPos.map(uvMapIndP)  = srcPosCand;
        uvMapIndG = get_uvmap_ind(size(NNF.srcTfmG.map), trgPixIndCur);
        NNF.srcTfmG.map(uvMapIndG) = srcTfmGCand;
        
        % Update matching cost
        NNF.uvCost(uvUpdatePos, :) = uvCostCand;
        
        nUpdate.propTemporal = nUpdate.propTemporal + size(uvUpdatePos, 1);
    end
    
    % === Spatial propagation:  along the direction [1, 0, 0] ===
    [NNF, n] = vc_propagate_spatial(trgPatch, videoColor, NNF, opt, 1);
    nUpdate.propSpatial = nUpdate.propSpatial + n;
    
    % === Spatial propagation: along the direction [0, 1, 0] ===
    [NNF, n] = vc_propagate_spatial(trgPatch, videoColor, NNF, opt, 2);
    nUpdate.propSpatial = nUpdate.propSpatial + n;
    
    % === Temporal propagation: along the direction [0, 0, -1] ===
    frameInc = 1;
    for indFrame = nFrame-1:-1:1
        % Temporal propagation
        if(initLvlFlag)
            [srcPosCand, srcTfmGCand, uvCostCand, uvUpdatePos] = ...
                vc_propgate_temporal_init(trgPatch, videoColor, NNF, opt, frameInc, indFrame);
        else
            [srcPosCand, srcTfmGCand, uvCostCand, uvUpdatePos] = ...
                vc_propagate_temporal(trgPatch, videoColor, ...
                videoFlowFw, videoFlowBw, [], NNF, opt, frameInc, indFrame);
        end
        
        % Skip the frame if there is no update
        if(isempty(uvUpdatePos))
            continue;
        end
        
        % Update NNF
        NNF.srcPos.data(uvUpdatePos, :)  = srcPosCand;
        NNF.srcTfmG.data(uvUpdatePos, :) = srcTfmGCand;
        
        % Update srcPos, srcTfmG maps
        trgPixIndCur = NNF.trgPix.ind(uvUpdatePos);
        uvMapIndP = get_uvmap_ind(size(NNF.srcPos.map), trgPixIndCur);
        NNF.srcPos.map(uvMapIndP)  = srcPosCand;
        uvMapIndG = get_uvmap_ind(size(NNF.srcTfmG.map), trgPixIndCur);
        NNF.srcTfmG.map(uvMapIndG) = srcTfmGCand;
        
        % Update matching cost
        NNF.uvCost(uvUpdatePos, :) = uvCostCand;
        
        nUpdate.propTemporal = nUpdate.propTemporal + size(uvUpdatePos, 1);
    end
    
    % === Spatial propagation: along the direction [-1, 0, 0] ===
    [NNF, n] = vc_propagate_spatial(trgPatch, videoColor, NNF, opt, 3);
    nUpdate.propSpatial = nUpdate.propSpatial + n;
    
    % === Spatial propagation: along the direction [0, -1, 0] ===
    [NNF, n] = vc_propagate_spatial(trgPatch, videoColor, NNF, opt, 4);
    nUpdate.propSpatial = nUpdate.propSpatial + n;
end

end

% =========================================================================
% Randomized search
% =========================================================================
function [srcPosCand, srcTfmGCand, uvCostCand, uvUpdatePos] = ...
    vc_random_search(trgPatch, videoColor, NNF, searchRadCur, uvActiveInd, opt)
% VC_RANDOM_SEARCH
%
% Coarse-to-fine search of the current nearest neighbor field
%
% Input
%   - trgPatch:     target patch      - [patchSize*patchSize] x [7] x [numPix]
%   - meanTrgPatch: mean target patch - [1] x [7] x [numPix]
%   - videoDataCF:  video color and flow - [imgH] x [imgW] x [7] x [nFrame]
%   - NNF:          nearest neighbor field
%   - opt:          parameters
% Output

% Initialization
uvUpdatePos   = [];
srcPosCand    = [];
srcTfmGCand   = [];
uvCostCand    = [];

% uvTrgIndPos   = find(NNF.trgPix.pnInd(:,indLabel));
% srcPosCur  = NNF.srcPos.data(uvTrgIndPos, :);
% srcTfmGCur = NNF.srcTfmG.data(uvTrgIndPos, :);

srcPosCur  = NNF.srcPos.data;
srcTfmGCur = NNF.srcTfmG.data;

% =====================================================================
% Get candidate source patches
% =====================================================================
% Prepare candiates by random sampling srcPos and uvSrcColorTfmG
[srcPosCand, srcTfmGCand] = vc_draw_rand_samples(srcPosCur, srcTfmGCur, searchRadCur);

% Filter out samples with invalid source patch positions
uvValidSrcInd  = vc_check_valid_uv(srcPosCand, NNF.validSrcPix.mask);

% Filter out samples with invalid scale
srcScaleCand = srcTfmGCand(:,1).*srcTfmGCand(:,4) - srcTfmGCand(:,2).*srcTfmGCand(:,3);
uvValidScaleInd = srcScaleCand < opt.maxPatchSc & srcScaleCand > opt.minPatchSc;

uvValidInd   = uvValidSrcInd & uvValidScaleInd & uvActiveInd;

uvValidPos = find(uvValidInd);

% Return if there are no valid patches to update
if(numel(uvValidPos) == 0)
    return;
end

% Get the source position and geometric transformation
srcPosCand  = srcPosCand(uvValidInd, :);
srcTfmGCand = srcTfmGCand(uvValidInd,:);

% Get the corresponding target patch
trgPatchCur = trgPatch(:,:,uvValidInd);

% Get previous patch matching cost
uvCostPrev  = sum(NNF.uvCost(uvValidInd,:), 2);

% =====================================================================
% Compute matching cost and identify patches to update
% =====================================================================
% Prepare source patch
srcPatchCur = vc_prep_source_patch(videoColor, srcPosCand, srcTfmGCand, NNF.patchRefPos);

% Compute patch matching cost
uvCostAppCand = vc_patch_cost_app(trgPatchCur, srcPatchCur, opt.wPatchM);
uvCostCand    = uvCostAppCand;

% Compu coherence cost
if(opt.useCoherence)
    uvCostCohCand = vc_patch_cost_coherence(NNF.srcPos.map, NNF.trgPixN, srcPosCand, ...
        uvValidPos, opt);
    uvCostCand = uvCostCand + uvCostCohCand;
end

% Check if the new candidate lower the energy
updateInd = uvCostCand < uvCostPrev;

% =====================================================================
% Update NNF data
% =====================================================================
% The updated target position
uvUpdatePos   = uvValidPos(updateInd);

% The updated data: srcPos, srcTfrmG, and uvCost
srcPosCand    = srcPosCand(updateInd,:);
srcTfmGCand   = srcTfmGCand(updateInd,:);
uvCostAppCand = uvCostAppCand(updateInd);
uvCostCohCand = uvCostCohCand(updateInd);
uvCostCand = cat(2, uvCostAppCand, uvCostCohCand);

end

% =========================================================================
% Spatial propagation
% =========================================================================
% function [NNF, nUpdateTotal] = vc_propagate_spatial(trgPatch, videoColor, ...
%     NNF, opt, indDirection)
% % VC_PROPAGATE_SPATIAL:
% % Spatial propagagtion using the generalized PatchMatch algorithm
% % Input:
% %   - trgPatch:     target patch         - [patchSize*patchSize] x [7] x [numPix]
% %   - meanTrgPatch: mean target patch    - [1] x [7] x [numPix]
% %   - videoDataCF:  video color and flow - [imgH] x [imgW] x [7] x [nFrame]
% %   - NNF:          nearest neighbor field
% %   - opt:          parameters
% %_  - indDirection: propagation direction
% % Output
%
% % Output:
% nUpdateTotal = 0;
%
% % Retrieve spatial neighbors
% trgPixN      = NNF.trgPixN{indDirection};
% uvValidPos   = find(trgPixN.validInd);
%
% % Initial valid neighboring pixels
% numUpdatePix = size(uvValidPos, 1);
%
% while(numUpdatePix ~= 0) % While there still active patches for propagation
%     % =====================================================================
%     % Get valid candidates (srcPosCand, srcTfmGCand)
%     % =====================================================================
%     % Get the source patch position and geometric transformation of the spatial-temporal neighbors
%     trgPosIndCur   = NNF.trgPix.ind(uvValidPos);
%     trgPosSubCur   = NNF.trgPix.sub(uvValidPos,:);
%
%     % Get the index of neighboring trgPix
%     trgPosNInd     = trgPixN.ind(uvValidPos);
%
%     % Get candidate source patch position and geometric transformation
%     srcPosNCand  = vc_uvMat_from_uvMap(NNF.srcPos.map,  trgPosNInd);
%     srcTfmGCand  = vc_uvMat_from_uvMap(NNF.srcTfmG.map, trgPosNInd);
%
%     % Update candidate source patch position by propagation
%     srcPosCand = vc_get_spatial_propagation(srcPosNCand, srcTfmGCand, opt.propDir(indDirection,:));
%
%     % =====================================================================
%     % Check if the srcPosCand is a valid patch
%     % =====================================================================
%     % Check if the candidates are valid
%     uvValidRangeInd = vc_check_valid_uv(srcPosCand, NNF.validSrcPix.mask);
%
%     % Check if the srcPos is different from the current one
%     srcPosCandPrev = vc_uvMat_from_uvMap(NNF.srcPos.map,  trgPosIndCur);
%     uvValidDistInd = sum(abs(srcPosCandPrev - srcPosCand), 2) > 0.5;
%
%     uvValidCandInd = uvValidRangeInd & uvValidDistInd;
%
%     % Use only valid patches
%     uvValidPos    = uvValidPos(uvValidCandInd);
%     if(size(uvValidPos, 1) == 0)
%         break;
%     end
%
%     % Get the valid candidates
%     trgPosIndCur = trgPosIndCur(uvValidCandInd);
%     trgPosSubCur = trgPosSubCur(uvValidCandInd,:);
%     srcPosCand   = srcPosCand(uvValidCandInd,:);
%     srcTfmGCand  = srcTfmGCand(uvValidCandInd,:);
%
%     % =====================================================================
%     % Get the corresponding target patch
%     % =====================================================================
%     % Get target patches
%     trgPatchCur  = trgPatch(:,:,uvValidPos);
%     % Get previous patch matching cost
%     uvCostPrev   = sum(NNF.uvCost(uvValidPos,:), 2);
%
%     % =====================================================================
%     % Compute matching cost and identify patches to update
%     % =====================================================================
%     % Prepare source patch
%     srcPatchCur = vc_prep_source_patch(videoColor, srcPosCand, srcTfmGCand, NNF.patchRefPos);
%
%     % Compute patch matching cost
%     uvCostAppCand = vc_patch_cost_app(trgPatchCur, srcPatchCur, opt.wPatchM);
%     uvCostCand    = uvCostAppCand;
%     if(opt.useCoherence)
%         uvCostCohCand = vc_patch_cost_coherence(NNF.srcPos.map, NNF.trgPixN, srcPosCand, ...
%             uvValidPos, opt);
%         uvCostCand = uvCostCand + uvCostCohCand;
%     end
%
%     updateInd = uvCostCand < uvCostPrev;
%
%     nUpdate = sum(updateInd);
%     nUpdateTotal = nUpdateTotal + nUpdate;
%
%     % =====================================================================
%     % Update NNF data
%     % =====================================================================
%     if(nUpdate ~= 0)   % Update the NNF data
%         uvUpdatePos  = uvValidPos(updateInd);
%         trgPosIndCur = trgPosIndCur(updateInd);
%
%         % Update srcPos, uvSrcColorTfmG
%         srcPosCand  = srcPosCand(updateInd,:);
%         srcTfmGCand = srcTfmGCand(updateInd,:);
%         NNF.srcPos.data(uvUpdatePos,  :) = srcPosCand;
%         NNF.srcTfmG.data(uvUpdatePos, :) = srcTfmGCand;
%
%         % Update uvMap
%         uvMapInd = get_uvmap_ind(size(NNF.srcPos.map), trgPosIndCur);
%         NNF.srcPos.map(uvMapInd) = srcPosCand;
%         uvMapInd = get_uvmap_ind(size(NNF.srcTfmG.map), trgPosIndCur);
%         NNF.srcTfmG.map(uvMapInd) = srcTfmGCand;
%
%         % Update matching cost
%         NNF.uvCost(uvUpdatePos, 1)  = uvCostAppCand(updateInd);
%         if(opt.useCoherence)
%             NNF.uvCost(uvUpdatePos,2) = uvCostCohCand(updateInd);
%         end
%     else
%         break;
%     end
%
%     % =====================================================================
%     % Update uvValidPos
%     % =====================================================================
%     trgPosSubCur  = trgPosSubCur(updateInd,:);
%     trgPixNextSub = bsxfun(@plus, trgPosSubCur, opt.propDir(indDirection, :));
%
%     % Get the index of the next propagation candidate
%     trgPixNextInd   = ones(nUpdate, 1, 'single');
%     uvValidNextSub  = vc_check_index_limit(trgPixNextSub, [NNF.imgW, NNF.imgH, NNF.nFrame]);
%     trgPixNextSub   = round(trgPixNextSub(uvValidNextSub,:));
%     trgPixNextInd(uvValidNextSub) = sub2ind([NNF.imgH, NNF.imgW, NNF.nFrame], ...
%         trgPixNextSub(:,2), trgPixNextSub(:,1), trgPixNextSub(:,3));
%
%     % Update the uvValidPos
%     updateMap = false(size(NNF.trgPix.mask));
%     updateMap(trgPixNextInd) = 1;
%     uvValidPos = find(updateMap(NNF.trgPix.ind) & trgPixN.validInd);
%
%     numUpdatePix = size(uvValidPos,1);
% end
%
%
% end

% =========================================================================
% Temporal propagation
% =========================================================================
function [srcPosCand, srcTfmGCand, uvCostCand, uvUpdatePos] = ...
    vc_propagate_temporal(trgPatch, videoColor, ...
    videoFlowTrg, videoFlowSrc, videoFlowConf, NNF, opt, frameInc, indFrame)

% VC_PROPAGATE_TEMPORAL:
% Temporal propagagtion using flow-guided PatchMatch algorithm
% Input:
%   - trgPatch:     target patch      - [patchSize*patchSize] x [7] x [numPix]
%   - meanTrgPatch: mean target patch - [1] x [7] x [numPix]
%   - videoDataCF:  video color and flow - [imgH] x [imgW] x [7] x [nFrame]
%   - NNF:          nearest neighbor field
%   - opt:          parameters
%_  - indDirection: propagation direction
% Output

% Initialization
srcPosCand    = [];
srcTfmGCand   = [];
uvCostCand    = [];
uvUpdatePos   = [];
uvValidPos    = [];

% patch reference position for computing local transformation due to flow
c    = round(opt.spPatchSize/2);
rInd = [c-opt.pSize, c+opt.pSize,c-1, c+1]';
patchRefPos  = NNF.patchRefPos(rInd, :);
patchRefPosC = bsxfun(@minus, patchRefPos, mean(patchRefPos, 1));
patchRefPosC = patchRefPosC(:,1:2);

% Get the trgPix at the current frame
uvValidIndCur  = NNF.trgPix.sub(:,3) == indFrame;
uvValidPosCur  = find(uvValidIndCur);

if(size(uvValidPosCur, 1) == 0)
    return;
end

% Target patch positions
trgPixSub  = NNF.trgPix.sub(uvValidIndCur, :);

% Target patch positions
trgPixNSub = vc_get_flow_neightbor(videoFlowTrg, NNF.trgPix.indF(uvValidIndCur,:), ...
    trgPixSub, frameInc);

% Check if the flow neigbhor is a valid target patch
uvValidTrgInd = vc_check_valid_uv(trgPixNSub, NNF.trgPix.mask);

% Check if the flow neigbhor is a valid source patch
uvValidSrcInd = vc_check_valid_uv(trgPixNSub, NNF.validSrcPix.mask);

% ====================================================================================
% Temporal propagation (when the temporal neighbor is target patches)
% ====================================================================================
if(sum(uvValidTrgInd) ~= 0)
    % Temporal neighbors
    trgPixNSubCur = trgPixNSub(uvValidTrgInd, :);
    uvValidTrgPos = uvValidPosCur(uvValidTrgInd);
    
    % Find the neighbor target patch index
    trgPixNSubCurInt = round(trgPixNSubCur);
    trgPixNIndCur    = int64(sub2ind([NNF.imgH, NNF.imgW, NNF.nFrame], ...
        trgPixNSubCurInt(:,2), trgPixNSubCurInt(:,1), trgPixNSubCurInt(:,3)));
    
    % Get candidate source patch position and geometric transformation
    srcPosNCand   = vc_uvMat_from_uvMap(NNF.srcPos.map,  trgPixNIndCur);
    srcTfmGNCand  = vc_uvMat_from_uvMap(NNF.srcTfmG.map, trgPixNIndCur);
    
    % Refine the source patch candidates to integer target patch positions
    refineVec = trgPixNSubCur(:,1:2) - trgPixNSubCurInt(:,1:2);
    refineVec = vc_apply_affine_tform(srcTfmGNCand, refineVec);
    srcPosNCand(:,1:2) = srcPosNCand(:,1:2) + refineVec;
    
    % Flow neighbor of source patches
    srcPosCandT = vc_get_temporal_propagation(srcPosNCand, videoFlowSrc, -frameInc);
    % Check if the flow neigbhor is a valid source patch
    uvValidSrcCand = vc_check_valid_uv(srcPosCandT, NNF.validSrcPix.mask);
    
    % === Case 1:  When the flow neighbors are source patches ===
    srcTfmGCandT = zeros(size(srcTfmGNCand), 'single');
    
    % Use target/source flow patches to compute srcTfmGCand
    trgPatchFlow = vc_prep_target_patch(videoFlowTrg, ...      % target flow patch
        NNF.trgPix.sub(uvValidTrgPos, :), patchRefPos);
    srcPatchFlow = vc_prep_source_patch(videoFlowSrc, ...      % source flow patch
        srcPosNCand(uvValidSrcCand,:), srcTfmGNCand(uvValidSrcCand,:), patchRefPos);
    % Compute the candidate transformation
    srcTfmGCandT(uvValidSrcCand, :) = ...
        vc_patch_tform_pred(trgPatchFlow(:,:,uvValidSrcCand), srcPatchFlow, ...
        srcTfmGNCand(uvValidSrcCand,:), patchRefPos);
    
    % === Case 2: When the flow neighbors are target patches ===
    % Replace the source candidate with the current source candidates
    srcPosCandT(~uvValidSrcCand,:) = srcPosNCand(~uvValidSrcCand,:);
    
    % Compute patch transformation
    trgTform = compute_tform_from_flow(trgPatchFlow(:,:,~uvValidSrcCand), patchRefPosC, []);
    srcTfmGCandT(~uvValidSrcCand, :) = ...
        vc_multiply_tform_matrix(srcTfmGNCand(~uvValidSrcCand, :), trgTform);
    
    % Remove source patches with invalid scales
    srcScaleCand = srcTfmGCandT(:,1).*srcTfmGCandT(:,4) - srcTfmGCandT(:,2).*srcTfmGCandT(:,3);
    uvValidScaleInd = srcScaleCand < opt.maxPatchSc & srcScaleCand > opt.minPatchSc;
    
    % Remove source patches with similar position with previous ones
    srcPosCandPrev = vc_uvMat_from_uvMap(NNF.srcPos.map,  NNF.trgPix.ind(uvValidTrgPos));
    uvValidDistInd = sum((srcPosCandPrev - srcPosCandT).^2, 2) > opt.minPatchSc;
    
    % Update valid source patches
    uvValidInd    = uvValidScaleInd & uvValidDistInd;
    
    srcPosCandT   = srcPosCandT(uvValidInd,:);
    srcTfmGCandT  = srcTfmGCandT(uvValidInd,:);
    uvValidTrgPos = uvValidTrgPos(uvValidInd);
    
    srcPosCand    = cat(1, srcPosCand,  srcPosCandT);
    srcTfmGCand   = cat(1, srcTfmGCand, srcTfmGCandT);
    uvValidPos    = cat(1, uvValidPos, uvValidTrgPos);
end

% ====================================================================================
% Temporal propagation (when the temporal neighbor is source patches)
% ====================================================================================
if(sum(uvValidSrcInd) ~= 0)
    % source patch candidate position
    srcPosCandS   = trgPixNSub(uvValidSrcInd, :);
    uvValidSrcPos = uvValidPosCur(uvValidSrcInd);
    
    % Use target patch flow to compute srcTfmGCand
    trgPatchFlow = vc_prep_target_patch(videoFlowTrg, NNF.trgPix.sub(uvValidSrcInd, :), patchRefPos);
    srcTfmGCandS = compute_tform_from_flow(trgPatchFlow, patchRefPosC, []);
    
    % Remove source patches with invalid scales
    srcScaleCand = srcTfmGCandS(:,1).*srcTfmGCandS(:,4) - srcTfmGCandS(:,2).*srcTfmGCandS(:,3);
    uvValidScaleInd = srcScaleCand < opt.maxPatchSc & srcScaleCand > opt.minPatchSc;
    % Remove source patches with similar position with previous ones
    srcPosCandPrev = vc_uvMat_from_uvMap(NNF.srcPos.map,  NNF.trgPix.ind(uvValidSrcPos));
    uvValidDistInd = sum((srcPosCandPrev - srcPosCandS).^2, 2) > opt.minPatchSc;
    
    % Update valid source patches
    uvValidInd    = uvValidScaleInd & uvValidDistInd;
    
    srcPosCandS   = srcPosCandS(uvValidInd,:);
    srcTfmGCandS  = srcTfmGCandS(uvValidInd,:);
    uvValidSrcPos = uvValidSrcPos(uvValidInd);
    
    % Update valid source patches
    srcPosCand    = cat(1, srcPosCand,  srcPosCandS);
    srcTfmGCand   = cat(1, srcTfmGCand, srcTfmGCandS);
    uvValidPos    = cat(1, uvValidPos, uvValidSrcPos);
end

if(isempty(uvValidPos))
    return;
end

% =====================================================================
% Get the corresponding target patch
% =====================================================================
% Get current target patch and patch matching cost
trgPatchCur  = trgPatch(:,:, uvValidPos);
uvCostPrev   = sum(NNF.uvCost(uvValidPos, :), 2);

% =====================================================================
% Compute matching cost and identify patches to update
% =====================================================================
% Prepare source patch
srcPatchCur = vc_prep_source_patch(videoColor, srcPosCand, srcTfmGCand, NNF.patchRefPos);

% Compute patch matching cost
uvCostAppCand = vc_patch_cost_app(trgPatchCur, srcPatchCur, opt.wPatchM);
uvCostCand    = uvCostAppCand;
if(opt.useCoherence)
    uvCostCohCand = vc_patch_cost_coherence(NNF.srcPos.map, NNF.trgPixN, srcPosCand, ...
        uvValidPos, opt);
    uvCostCand = uvCostCand + uvCostCohCand;
end

updateInd = uvCostCand < uvCostPrev;

% =====================================================================
% Update NNF data
% =====================================================================
uvUpdatePos  = uvValidPos(updateInd);

% Update srcPos, srcTfmG, uvCost
srcPosCand    = srcPosCand(updateInd, :);
srcTfmGCand   = srcTfmGCand(updateInd,:);
uvCostAppCand = uvCostAppCand(updateInd);
uvCostCohCand = uvCostCohCand(updateInd);
uvCostCand    = cat(2, uvCostAppCand, uvCostCohCand);

end

function [srcPosCand, srcTfmGCand, uvCostCand, uvUpdatePos] = ...
    vc_propgate_temporal_init(trgPatch, videoColor, NNF, opt, frameInc, indFrame)

% Initialization
srcPosCand    = [];
srcTfmGCand   = [];
uvCostCand    = [];
uvUpdatePos   = [];
uvValidPos    = [];

% Get the trgPix at the current frame
uvValidIndCur  = NNF.trgPix.sub(:,3) == indFrame;
uvValidPosCur  = find(uvValidIndCur);

if(size(uvValidPosCur, 1) == 0)
    return;
end

% Target patch positions at the current frame
trgPixSub  = NNF.trgPix.sub(uvValidIndCur, :);

% Target patch positions: apply offset [0, 0, frameInc]
trgPixNSub      = trgPixSub;
trgPixNSub(:,3) = trgPixNSub(:,3) + frameInc;

% Check if the flow neigbhor is a valid target patch
uvValidTrgInd = vc_check_valid_uv(trgPixNSub, NNF.trgPix.mask);

% Check if the flow neigbhor is a valid source patch
uvValidSrcInd = vc_check_valid_uv(trgPixNSub, NNF.validSrcPix.mask);

% ====================================================================================
% Temporal propagation (when the temporal neighbor is a target patch)
% ====================================================================================
if(sum(uvValidTrgInd) ~= 0)
    % Temporal neighbors
    trgPixNSubCur = trgPixNSub(uvValidTrgInd, :);
    uvValidTrgPos = uvValidPosCur(uvValidTrgInd);
    
    % Find the neighbor target patch index
    trgPixNIndCur = int64(sub2ind([NNF.imgH, NNF.imgW, NNF.nFrame], ...
        trgPixNSubCur(:,2), trgPixNSubCur(:,1), trgPixNSubCur(:,3)));
    
    % Get candidate source patch position and geometric transformation
    srcPosNCand   = vc_uvMat_from_uvMap(NNF.srcPos.map,  trgPixNIndCur);
    
    % The temporally propagated source patch
    srcPosCandT      = srcPosNCand;
    srcPosCandT(:,3) = srcPosCandT(:,3) - frameInc;
    
    % Check if the flow neigbhor is a valid source patch
    uvValidSrcCand = vc_check_valid_uv(srcPosCandT, NNF.validSrcPix.mask);
    
    % Update the source patch candidates
    srcPosCandT   = srcPosCandT(uvValidSrcCand,:);
    uvValidTrgPos = uvValidTrgPos(uvValidSrcCand);
    
    srcPosCand    = cat(1, srcPosCand,  srcPosCandT);
    uvValidPos    = cat(1, uvValidPos, uvValidTrgPos);
end

% ====================================================================================
% Temporal propagation (when the temporal neighbor is source patches)
% ====================================================================================
if(sum(uvValidSrcInd) ~= 0)
    % source patch candidate position
    srcPosCandS   = trgPixNSub(uvValidSrcInd, :);
    uvValidSrcPos = uvValidPosCur(uvValidSrcInd);
    
    % Update valid source patches
    srcPosCand    = cat(1, srcPosCand,  srcPosCandS);
    uvValidPos    = cat(1, uvValidPos, uvValidSrcPos);
end

srcTfmGCand = zeros(size(srcPosCand,1), 4, 'single');
srcTfmGCand(:,[1,4]) = 1;

if(isempty(uvValidPos))
    return;
end

% =====================================================================
% Get the corresponding target patch
% =====================================================================
% Get current target patch and patch matching cost
trgPatchCur  = trgPatch(:,:, uvValidPos);
uvCostPrev   = sum(NNF.uvCost(uvValidPos, :), 2);

% =====================================================================
% Compute matching cost and identify patches to update
% =====================================================================
% Prepare source patch
srcPatchCur = vc_prep_source_patch(videoColor, srcPosCand, srcTfmGCand, NNF.patchRefPos);

% Compute patch matching cost
uvCostAppCand = vc_patch_cost_app(trgPatchCur, srcPatchCur, opt.wPatchM);
uvCostCand    = uvCostAppCand;
if(opt.useCoherence)
    uvCostCohCand = vc_patch_cost_coherence(NNF.srcPos.map, NNF.trgPixN, srcPosCand, ...
        uvValidPos, opt);
    uvCostCand = uvCostCand + uvCostCohCand;
end

updateInd = uvCostCand < uvCostPrev;

% =====================================================================
% Update NNF data
% =====================================================================
uvUpdatePos  = uvValidPos(updateInd);

% Update srcPos, srcTfmG, uvCost
srcPosCand    = srcPosCand(updateInd, :);
srcTfmGCand   = srcTfmGCand(updateInd,:);
uvCostAppCand = uvCostAppCand(updateInd);
uvCostCohCand = uvCostCohCand(updateInd);
uvCostCand    = cat(2, uvCostAppCand, uvCostCohCand);

end

% =========================================================================
% Utility functions for propagation
% =========================================================================

function patchTfmG = compute_tform_from_flow(patchFlow, patchRefPos, srcTfmG)

% Flow neighbor position
numPix = size(patchFlow, 3);

if(isempty(srcTfmG))
    pRefPos = patchRefPos(:,:, ones(numPix,1));
else
    pRefPos = vc_apply_affine_tform_patch(srcTfmG, patchRefPos);
end

% Target patch position
pRefPosN = pRefPos + patchFlow;
pRefPosN = bsxfun(@minus, pRefPosN, mean(pRefPosN, 1));

% Compute patch transformation from two point sets
patchTfmG = vc_compute_affine_2d(pRefPos, pRefPosN);

end

function  srcTfmG = vc_patch_tform_pred(trgPatchFlow, srcPatchFlow, srcTfmG, patchRefPos)

% VC_PATCH_TFORM_PRED: Patch geometric transformation prediction using flow-based guidnace
%
% Input
%   - trgPatchFlow: [pSize*pSize] x [2] x [numPix]
%   - srcPatchFlow: [pSize*pSize] x [2] x [numPix]
%   - srcTfmG:      [numPix] x [4]
%   - patchRefPos:  [pSize*pSize] x [3]
% Output

patchRefPosC = patchRefPos(:,1:2);
patchRefPosC = bsxfun(@minus, patchRefPosC, mean(patchRefPosC, 1));

% =========================================================================
% Prepare target patch positions in two frames
% =========================================================================
% Target patch flow neighbor position
trgTform = compute_tform_from_flow(trgPatchFlow, patchRefPosC, []);

% trgRefPosN  = patchRefPosC(:,:, ones(numPix,1));
%
% % Target patch position
% trgRefPos = trgRefPosN + trgPatchFlow;
% trgRefPos = bsxfun(@minus, trgRefPos, mean(trgRefPos, 1));
%
% % Compute patch transformation from two point sets
% trgTform = vc_compute_affine_2d(trgRefPos, trgRefPosN);


% =========================================================================
% Prepare source patch positions in two frames
% =========================================================================
srcTform = compute_tform_from_flow(srcPatchFlow, patchRefPosC, srcTfmG);
% Source patch flow neighbor position
% srcRefPosN  = vc_apply_affine_tform_patch(srcTfmG, patchRefPosC);
% srcRefPosN  = bsxfun(@minus, srcRefPosN, mean(srcRefPosN, 1));
%
% % Source patch position
% srcRefPos = srcRefPosN + srcPatchFlow;
% srcRefPos = bsxfun(@minus, srcRefPos, mean(srcRefPos, 1));
%
% % Compute patch transformation from two point sets
% srcTform = vc_compute_affine_2d(srcRefPosN, srcRefPos);

% =========================================================================
% Patch transformation prediction
% =========================================================================
% srcTfmG_Pred = srcTform*srcTfmG*trgTform;
srcTfmG = vc_multiply_tform_matrix(srcTfmG, trgTform);
srcTfmG = vc_multiply_tform_matrix(srcTform, srcTfmG);

end

% =========================================================================
% Utility functions for random search
% =========================================================================
function [srcPos, srcTformG] = vc_draw_rand_samples(srcPos, srcTformG, searchRad)

% Draw random samples in x, y, t, scale, rotation
% srcPos:           [numPix] x [3]
% uvSrcTformG: [uvSrcTformG] x [4]

% Number of candidate pixels
numPix = size(srcPos, 1);

% =========================================================================
% Draw positional samples
% =========================================================================

% Draw random samples in spatial domain
randOffsetS   = (rand(numPix, 2) - 0.5)*diag(searchRad(1:2));

srcPos(:,1:2) = bsxfun(@plus, srcPos(:,1:2), randOffsetS);

% Draw random samples in temporal domain
randOffsetT = randi([-searchRad(3), searchRad(3)], numPix, 1);
srcPos(:,3) = srcPos(:,3) + randOffsetT;

% INTERGER PIXELS
% srcPos = round(srcPos);

% =========================================================================
% Draw a random affine transformation and compute the composite
% =========================================================================
% Create affine transformation from randomly sampled parameters
randVec = rand(numPix, 4) - 0.5;
scale = randVec(:,1)*searchRad(4);   % scale
scale = scale + 1;                   % perturb around one
theta = randVec(:,2)*searchRad(5);   % rot
sh_x  = randVec(:,3)*searchRad(6);   % sheer x
sh_y  = randVec(:,4)*searchRad(6);   % sheer y

% Create a affine perturbation matrix
srcTformD = zeros(numPix, 4, 'single');
srcTformD(:,1) = cos(theta) - sin(theta).*sh_y;
srcTformD(:,2) = sin(theta) + cos(theta).*sh_y;
srcTformD(:,3) = cos(theta).*sh_x - sin(theta);
srcTformD(:,4) = sin(theta).*sh_x + cos(theta);

srcTformD = bsxfun(@times, srcTformD, scale);

% Compute transformation composition
srcTformG = vc_multiply_tform_matrix(srcTformD, srcTformG);


end

function     uvRepSrcInd = check_repetition(srcPosMap, trgPos, srcPos, opt)

numPix = size(trgPos,1);
[imgH, imgW, nFrame, ~] = size(srcPosMap);

% initialize coherence cost
uvRepSrcInd = true(numPix, 1);

for i = opt.spatialPropInd
    % source patch position prediction
    v = opt.propDir(i,:);
    
    % source patch positions of neighboring target patches
    trgPosN = bsxfun(@plus, trgPos, v);
    trgIndN = sub2ind([imgH, imgW, nFrame], trgPosN(:,2), trgPosN(:,1), trgPosN(:,3));
    srcPosN = vc_uvMat_from_uvMap(srcPosMap,  trgIndN);
    
    % source patch offsets
    srcPosD = srcPos - srcPosN;
    
    % cost on spatial coherence
    %     invalidSrc = (sum(srcPosD(:,1:2).^2, 2) < opt.minPatchSc.^2) & ...
    %         (srcPosD(:,3) == 0);
    invalidSrc = (sum(srcPosD(:,1:2).^2, 2) < 1) & ...
        (srcPosD(:,3) == 0);
    
    uvRepSrcInd(invalidSrc) = 0;
end

end
