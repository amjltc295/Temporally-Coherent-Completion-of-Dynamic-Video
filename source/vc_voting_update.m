function videoData = vc_voting_update(videoData, NNF, holeMask, opt)


%%

% Fast voting update, instead of computing the weighted average from all
% source patches, here we only update patches that have been updated

[imgH, imgW, nCh, nFrame] = size(videoData);

numUvPix = sum(NNF.updateInd);
if(numUvPix~=0)
    
    % Prepare source patch
    uvTcur = NNF.uvT.data(NNF.updateInd, :);
    srcPatch = vc_prep_source_patch(videoData, uvTcur, NNF.uvSrcRefPos);
    
    % Update NNF data
    trgPatchInd = NNF.trgPatchInd(:, NNF.updateInd);
    
    % Prepare spatial-temporal patch weight
    wPatchCurD = NNF.wPatchST(opt.pMidPix, 1, :,NNF.updateInd);
    wPatchCurD = reshape(wPatchCurD, [1, 1, size(wPatchCurD,4)]);
    % Prepare cost-based patch weight
    sigmaInv = 1/(mean(NNF.uvCost));
    wPatchCurC =  exp(-0.5*sigmaInv*(NNF.uvCost(NNF.updateInd)))';
    wPatchCurC = reshape(wPatchCurC, [1, 1, size(wPatchCurC,2)]);

    wPatchCur  = wPatchCurC.*wPatchCurD;
    
    % Apply the bias correction
    if(opt.useBiasCorrection) 
        uvBiasCur = NNF.uvBias(:,NNF.updateInd);
        uvBiasCur = reshape(uvBiasCur, 1, 3, numUvPix);
        srcPatch  = bsxfun(@plus, srcPatch, uvBiasCur);
    end
    
    % Apply the weight for the source patch
    srcPatch = bsxfun(@times, srcPatch, wPatchCur);
    
    % Compute weighted average from source patches
    videoDataAcc = zeros(size(videoData));
    for iCh = 1: nCh
        videoDataChAcc = opt.voteUpdateW*squeeze(videoData(:,:,iCh,:));
        for i = 1: numUvPix
            videoDataChAcc(trgPatchInd(:,i)) = videoDataChAcc(trgPatchInd(:,i)) + srcPatch(:,iCh,i);
        end
        videoDataAcc(:,:,iCh,:) = videoDataChAcc;
    end
    
    % Compute weights 
    wPatchCur = squeeze(wPatchCur);
    weightAcc = opt.voteUpdateW*ones(imgH, imgW, nFrame);
    for i = 1: numUvPix
        weightAcc(trgPatchInd(:,i)) = weightAcc(trgPatchInd(:,i)) + wPatchCur(i);
    end
    weightAcc = reshape(weightAcc, imgH, imgW, 1, nFrame);
    videoDataAcc = bsxfun(@rdivide, videoDataAcc, weightAcc);
    
    % Merge with known region
    holeMask = reshape(holeMask, imgH, imgW, 1, nFrame);
    holeMask = repmat(holeMask, [1, 1, nCh, 1]);    
    videoData(holeMask) = videoDataAcc(holeMask);
end
