function flowPatch =  vc_prep_flow_patch(videoFlow, uvPixSub, uvRefPos)

% flowPatch: [spPatchSize] x [nCh ] x [nFlow] x [numUvPix]
% [25] x [2] x [2] x [numUvPix]

[imgH, imgW, nCh, nFrame, nFlow] = size(videoFlow);

numUvPix = size(uvPixSub, 1);
pNumPix  = size(uvRefPos, 1);

% Prepare patch position
patchPosCenter = reshape(uvPixSub', 1, 3, numUvPix);
uvPatchPos = bsxfun(@plus, uvRefPos, patchPosCenter);

% Avoid sample out of boundary positions
uvPatchPos = max(uvPatchPos, 1);
uvPatchPos(:,1,:) = min(uvPatchPos(:,1,:), imgW);
uvPatchPos(:,2,:) = min(uvPatchPos(:,2,:), imgH);
uvPatchPos(:,3,:) = min(uvPatchPos(:,3,:), nFrame);

% 
uvPatchPosX = squeeze(uvPatchPos(:,1,:));
uvPatchPosY = squeeze(uvPatchPos(:,2,:));

% Initialize trgPatch
flowPatch = zeros(pNumPix, numUvPix, nFlow, nCh, 'single');

% Prepare target patch values
uvTime = vc_clamp(uvPixSub(:,3), 1, nFrame);
tIndSet = unique(uvTime);

for i = 1: length(tIndSet)
    iFrame = tIndSet(i);
    indCurFrame = (uvTime == iFrame);
    
    % Forward flow
    flowPatch(:,indCurFrame, 1, :) = mexinterp2(videoFlow(:,:,:, iFrame, 1), ...
        uvPatchPosX(:,indCurFrame), uvPatchPosY(:,indCurFrame));
    % Backward flow
    flowPatch(:,indCurFrame, 2, :) = mexinterp2(videoFlow(:,:,:, iFrame, 2), ...
        uvPatchPosX(:,indCurFrame), uvPatchPosY(:,indCurFrame));
end

% Reshape the flow patch to [spPatchSize] x [nCh] x [nFlow] x [numUvPix]
flowPatch = permute(flowPatch, [1, 4, 3, 2]);

end
