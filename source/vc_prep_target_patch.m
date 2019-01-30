function trgPatch = vc_prep_target_patch(videoData, trgPos, patchRefPos)

% VC_PREP_PATCH: Get target patches at specified positions
%
% Input:
%   - videoData:   video data - [imgH] x [imgW] x [nCh] x [nFrame]
%   - uvPixSub:    target patch center positions [numUvPix] x [3]
%   - uvTrgRefPos: reference coordinate for a patch
%
% Output:
%   - trgPatch:    target patch [patchSize*patchSize] x [3] x [numUvPix]

% Get dimensions
[imgH, imgW, nCh, nFrame] = size(videoData);

numPix  = size(trgPos, 1);             % number of target patches
pNumPix = size(patchRefPos, 1);        % number of pixels in a patch

% Prepare target patch position
trgPatchPosCenter = reshape(trgPos', 1, 3, numPix);
trgPatchPos = bsxfun(@plus, patchRefPos, trgPatchPosCenter);

% Convert target patch position to index
trgPatchInd = zeros(pNumPix, nCh, numPix);
for i = 1: nCh
    trgPatchInd(:, i, :) = sub2ind([imgH, imgW, nCh, nFrame], ...
        trgPatchPos(:,2,:), trgPatchPos(:,1,:), ...
        i*ones(pNumPix, 1, numPix), trgPatchPos(:,3,:));
end

% Get target patch by matrix indexing
trgPatch = videoData(trgPatchInd);

end