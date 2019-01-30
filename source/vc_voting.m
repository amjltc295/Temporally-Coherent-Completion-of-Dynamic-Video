function [colorData, flowData] = vc_voting(videoData, videoFlow, NNF)

% VC_VOTING: spatial patch voting

% TO-DO: color-guided flow voting

colorInd    = [1,2,3];
flowFwInd   = [4, 5];
flowBwInd   = [6, 7];
% nCh         = 7;     % 3 color + 2 foreward flow + 2 backward flow

nChColor    = 3;
nChFlow     = 4;

% ========================================================================================
% Prepare color and flow source patch
% ========================================================================================
videoCF  = cat(3, videoData, videoFlow(:,:,1:4,:));

% Grab source patches
srcPatch = vc_prep_source_patch(videoCF, NNF.srcPos.data, NNF.srcTfmG.data, NNF.patchRefPos);
[srcPatchColor, srcPatchFlow] = ...
    deal(srcPatch(:, colorInd, :), srcPatch(:, [flowFwInd, flowBwInd], :));

% Apply range flow transformation
if(0)
    srcPatchFlow(:,1:2,:) = vc_apply_flow_tform(NNF.srcTfmFw, srcPatchFlow(:,1:2,:));
    srcPatchFlow(:,3:4,:) = vc_apply_flow_tform(NNF.srcTfmBw, srcPatchFlow(:,3:4,:));
end

% Compute flow weight
sigmaC  = 10;
pMidPix = round(size(srcPatch, 1)/2);
wPatchF = bsxfun(@minus, srcPatchColor(:,1,:), srcPatchColor(pMidPix,1,:));
wPatchF = exp(-wPatchF.^2/(2*sigmaC^2));
wPatchF = wPatchF.*NNF.wPatchR;
% ========================================================================================
% Color and flow voting
% ========================================================================================
% Apply the weighting for the source patch
srcPatchColor = bsxfun(@times, srcPatchColor, NNF.wPatchR);
srcPatchFlow  = bsxfun(@times, srcPatchFlow,      wPatchF);

% Voting
colorData  = zeros(NNF.holePix.numPix + 1, nChColor, 'single');
flowData   = zeros(NNF.holePix.numPix + 1, nChFlow,  'single');
wPatchFSum = zeros(NNF.holePix.numPix + 1,       1,  'single');

for ii = 1: size(srcPatch, 3)
    indCur = NNF.holePatch.ind(:,ii);
    
    % Counting color votes
    colorData(indCur,:) = colorData(indCur,:) + srcPatchColor(:,:,ii);
    % Counting flow votes
    flowData(indCur,:)  = flowData(indCur,:)  + srcPatchFlow(:,:,ii);
    wPatchFSum(indCur)  = wPatchFSum(indCur)  + wPatchF(:,:,ii);
end

% Normalization
colorData = bsxfun(@rdivide, colorData, NNF.holePatch.wSum);
flowData  = bsxfun(@rdivide, flowData,  wPatchFSum);

colorData = colorData(1:end-1,:);
flowData  = flowData(1:end-1, :);
% % Return result
% [colorData, flowData] = ...
%     deal(colorData(:,colorInd), colorData(:,[flowFwInd, flowBwInd]));

end

