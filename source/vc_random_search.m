function     [NNF, nUpdateTotal] = vc_random_search(trgPatch, videoData, NNF, opt)

%%

%%
[imgH, imgW, nCh, nFrame] = size(videoData);

% Search range
searchRad = [imgH, imgW, 2*nFrame];

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

    % === Prepare uvT candidates: uvTCand ===
    uvTCand = NNF.uvT.data;
    
    % Draw random samples in spatial domain
    randOffsetS = (rand(numUvPix, 2) - 0.5)*diag(searchRad(1:2));
    uvTCand(:,1:2) = bsxfun(@plus, uvTCand(:,1:2), randOffsetS);

    % Draw random samples in temporal domain 
    randOffsetT = randi([-searchRad(3), searchRad(3)], numUvPix, 1);
    uvTCand(:,3) = uvTCand(:,3) + randOffsetT;

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
        trgPatchCur      = trgPatch(:,:,uvValidInd);
        uvCostDataCur    = NNF.uvCost(uvValidInd);
        uvTCandCur       = uvTCand(uvValidInd, :);
        
        uvPixValidInd = NNF.uvPix.ind(uvValidInd);
        
        wPatchCur  = NNF.wPatchST(:,:,:,uvValidInd);
        
        % Grab source patches
        srcPatchCur = vc_prep_source_patch(videoData, uvTCandCur, NNF.uvSrcRefPos);
        
        % Compute patch matching cost
        [uvCostCand, uvBiasCand] = ...
            vc_patch_cost(trgPatchCur, srcPatchCur, wPatchCur, opt);
        
        % Check which one to update
        updateInd = (uvCostCand < uvCostDataCur);
        nUpdate = sum(updateInd);
        
        if(nUpdate~=0)
            uvPixActivePos = uvPixActivePos(updateInd);
            uvPixValidInd  = uvPixValidInd(updateInd);
            nUpdateTotal = nUpdateTotal + nUpdate;
            
            % === Update NNF data ===
            uvTCandCur = uvTCandCur(updateInd, :);
            NNF.uvT.data(uvPixActivePos, :) = uvTCandCur;
            NNF.uvT.map    = vc_update_uvMap(NNF.uvT.map, uvTCandCur, uvPixValidInd);
            
            NNF.uvCost(uvPixActivePos) = uvCostCand(updateInd);
            NNF.updateInd(uvPixActivePos)       = 1;
            
            if(opt.useBiasCorrection)
                NNF.uvBias(:,uvPixActivePos) = uvBiasCand(:,updateInd);
            end
        end
    end
end


end