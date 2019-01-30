function videoFlow = vc_voting_update_flow(videoFlow, NNF, holeMask, opt)

%%

% Fast voting update, instead of computing the weighted average from all
% source patches, here we only update patches that have been updated

[imgH, imgW, nCh, nFrame, nFlow] = size(videoFlow);

numUvPix = sum(NNF.updateInd);
if(numUvPix~=0)
    
    % === Prepare source patches ===
    uvTcur = NNF.uvT.data(NNF.updateInd, :);
    srcPatch = vc_prep_flow_patch(videoFlow, uvTcur,  NNF.uvSrcRefPos);
    
    % === Apply the motion field transformation ===
    uvFlowTformA = NNF.uvFlowTformA.data(:,:,NNF.updateInd);
    srcPatchT = vc_apply_flow_tform(srcPatch, uvFlowTformA);
    uvFlowTformT = NNF.uvFlowTformT.data(:,:,NNF.updateInd);
    uvFlowTformT = reshape(uvFlowTformT, [1, size(uvFlowTformT)]);
    srcPatch = bsxfun(@plus, srcPatchT, uvFlowTformT);
    
    % === Prepare spatial-temporal patch weight ===
    wPatchCurD = NNF.wPatchST(opt.pMidPix, 1, :,NNF.updateInd);
    wPatchCurD = reshape(wPatchCurD, [1, 1, size(wPatchCurD,4)]);
    % Prepare cost-based patch weight
    sigmaInv = 1/(mean(NNF.uvCost));
    wPatchCurC =  exp(-0.5*sigmaInv*(NNF.uvCost(NNF.updateInd)))';
    wPatchCurC = reshape(wPatchCurC, [1, 1, size(wPatchCurC,2)]);
    
    % Combine two weights
    wPatchCur  = wPatchCurC.*wPatchCurD;
    wPatchCur  = reshape(wPatchCur, [1, 1, 1, numUvPix]);
    
    % Apply the weight for the source patch
    srcPatch = bsxfun(@times, srcPatch, wPatchCur);
    
    % Get the target patch indices
    trgPatchInd = NNF.trgPatchInd(:, NNF.updateInd);
    
    % Compute weighted average from source patches
    videoFlowAcc = zeros(size(videoFlow));
    for iCh = 1: nCh
        for iFlow = 1:nFlow
            videoFlowChAcc = opt.voteUpdateW*squeeze(videoFlow(:,:,iCh,:,iFlow));
            for i = 1: numUvPix
                videoFlowChAcc(trgPatchInd(:,i)) = videoFlowChAcc(trgPatchInd(:,i)) + srcPatch(:,iCh,iFlow,i);
            end
            videoFlowAcc(:,:,iCh,:,iFlow) = videoFlowChAcc;
        end
    end
    
    % Compute weights
    wPatchCur = squeeze(wPatchCur);
    weightAcc = opt.voteUpdateW*ones(imgH, imgW, nFrame);
    for i = 1: numUvPix
        weightAcc(trgPatchInd(:,i)) = weightAcc(trgPatchInd(:,i)) + wPatchCur(i);
    end
    weightAcc = reshape(weightAcc, imgH, imgW, 1, nFrame, 1);
    videoFlowAcc = bsxfun(@rdivide, videoFlowAcc, weightAcc);
     
    % Merge with known region
    holeMask = reshape(holeMask, imgH, imgW, 1, nFrame, 1);
    holeMask = repmat(holeMask, [1, 1, nCh, 1, nFlow]);
    videoFlow(holeMask) = videoFlowAcc(holeMask);
end



end