function [NNF, nUpdateTotal] = vc_propagate_spatial(trgPatch, videoColor, ...
    NNF, opt, indDirection)
% VC_PROPAGATE_SPATIAL:
% Spatial propagagtion using the generalized PatchMatch algorithm
% Input:
%   - trgPatch:     target patch         - [patchSize*patchSize] x [7] x [numPix]
%   - meanTrgPatch: mean target patch    - [1] x [7] x [numPix]
%   - videoDataCF:  video color and flow - [imgH] x [imgW] x [7] x [nFrame]
%   - NNF:          nearest neighbor field
%   - opt:          parameters
%_  - indDirection: propagation direction
% Output

% Output:
nUpdateTotal = 0;

% Retrieve spatial neighbors
trgPixN      = NNF.trgPixN{indDirection};
uvValidPos   = find(trgPixN.validInd);

% Initial valid neighboring pixels
numUpdatePix = size(uvValidPos, 1);

while(numUpdatePix ~= 0) % While there still active patches for propagation
    % =====================================================================
    % Get valid candidates (srcPosCand, srcTfmGCand)
    % =====================================================================
    % Get the source patch position and geometric transformation of the spatial-temporal neighbors
    trgPosIndCur   = NNF.trgPix.ind(uvValidPos);
    trgPosSubCur   = NNF.trgPix.sub(uvValidPos,:);
    
    % Get the index of neighboring trgPix
    trgPosNInd     = trgPixN.ind(uvValidPos);
    
    % Get candidate source patch position and geometric transformation
    srcPosNCand  = vc_uvMat_from_uvMap(NNF.srcPos.map,  trgPosNInd);
    srcTfmGCand  = vc_uvMat_from_uvMap(NNF.srcTfmG.map, trgPosNInd);
    
    % Update candidate source patch position by propagation
    srcPosCand = vc_get_spatial_propagation(srcPosNCand, srcTfmGCand, opt.propDir(indDirection,:));
    
    % =====================================================================
    % Check if the srcPosCand is a valid patch
    % =====================================================================
    % Check if the candidates are valid
    uvValidRangeInd = vc_check_valid_uv(srcPosCand, NNF.validSrcPix.mask);
    
    % Check if the srcPos is different from the current one
    srcPosCandPrev = vc_uvMat_from_uvMap(NNF.srcPos.map,  trgPosIndCur);
    uvValidDistInd = sum(abs(srcPosCandPrev - srcPosCand), 2) > 0.5;
    
    uvValidCandInd = uvValidRangeInd & uvValidDistInd;
    
    % Use only valid patches
    uvValidPos    = uvValidPos(uvValidCandInd);
    if(size(uvValidPos, 1) == 0)
        break;
    end
    
    % Get the valid candidates
    trgPosIndCur = trgPosIndCur(uvValidCandInd);
    trgPosSubCur = trgPosSubCur(uvValidCandInd,:);
    srcPosCand   = srcPosCand(uvValidCandInd,:);
    srcTfmGCand  = srcTfmGCand(uvValidCandInd,:);
    
    % =====================================================================
    % Get the corresponding target patch
    % =====================================================================
    % Get target patches
    trgPatchCur  = trgPatch(:,:,uvValidPos);
    % Get previous patch matching cost
    uvCostPrev   = sum(NNF.uvCost(uvValidPos,:), 2);
    
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
    
    nUpdate = sum(updateInd);
    nUpdateTotal = nUpdateTotal + nUpdate;
    
    % =====================================================================
    % Update NNF data
    % =====================================================================
    if(nUpdate ~= 0)   % Update the NNF data
        uvUpdatePos  = uvValidPos(updateInd);
        trgPosIndCur = trgPosIndCur(updateInd);
        
        % Update srcPos, uvSrcColorTfmG
        srcPosCand  = srcPosCand(updateInd,:);
        srcTfmGCand = srcTfmGCand(updateInd,:);
        NNF.srcPos.data(uvUpdatePos,  :) = srcPosCand;
        NNF.srcTfmG.data(uvUpdatePos, :) = srcTfmGCand;
        
        % Update uvMap
        uvMapInd = get_uvmap_ind(size(NNF.srcPos.map), trgPosIndCur);
        NNF.srcPos.map(uvMapInd) = srcPosCand;
        uvMapInd = get_uvmap_ind(size(NNF.srcTfmG.map), trgPosIndCur);
        NNF.srcTfmG.map(uvMapInd) = srcTfmGCand;
        
        % Update matching cost
        NNF.uvCost(uvUpdatePos, 1)  = uvCostAppCand(updateInd);
        if(opt.useCoherence)
            NNF.uvCost(uvUpdatePos,2) = uvCostCohCand(updateInd);
        end
    else
        break;
    end
    
    % =====================================================================
    % Update uvValidPos
    % =====================================================================
    trgPosSubCur  = trgPosSubCur(updateInd,:);
    trgPixNextSub = bsxfun(@plus, trgPosSubCur, opt.propDir(indDirection, :));
    
    % Get the index of the next propagation candidate
    trgPixNextInd   = ones(nUpdate, 1, 'single');
    uvValidNextSub  = vc_check_index_limit(trgPixNextSub, [NNF.imgW, NNF.imgH, NNF.nFrame]);
    trgPixNextSub   = round(trgPixNextSub(uvValidNextSub,:));
    trgPixNextInd(uvValidNextSub) = sub2ind([NNF.imgH, NNF.imgW, NNF.nFrame], ...
        trgPixNextSub(:,2), trgPixNextSub(:,1), trgPixNextSub(:,3));
    
    % Update the uvValidPos
    updateMap = false(size(NNF.trgPix.mask));
    updateMap(trgPixNextInd) = 1;
    uvValidPos = find(updateMap(NNF.trgPix.ind) & trgPixN.validInd);
    
    numUpdatePix = size(uvValidPos,1);
end


end
