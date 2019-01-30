function srcPatch = vc_prep_source_patch(videoData, srcPos, srcTfmG, patchRefPos)

% VC_PREP_SOURCE_PATCH: grab source patch from the source patch position
% and patch transformation

[~, ~, nCh, nFrame] = size(videoData);
numPatch = size(srcPos, 1);         % Number of source patches
pNumPix  = size(patchRefPos, 1);    % Patch size

% Apply source patch transformation
srcRefPosTfmG = apply_affine_tform_patch(srcTfmG, patchRefPos(:,1:2));

% Prepare source patch position
srcPatchPosCenter = reshape(srcPos(:,1:2)', 1, 2, numPatch);
srcPatchPos  = bsxfun(@plus, srcPatchPosCenter, srcRefPosTfmG);
srcPatchPosX = squeeze(srcPatchPos(:,1,:));
srcPatchPosY = squeeze(srcPatchPos(:,2,:));

% Initialize trgPatch
srcPatch = zeros(pNumPix, numPatch, nCh, 'single');

% Get source patches at each frame
for indFrame = 1: nFrame
    % Current frame
    indCurFrame = srcPos(:,3) == indFrame;
    
    srcPatch(:,indCurFrame,:) = vgg_interp2(videoData(:,:,:, indFrame), ...
        srcPatchPosX(:,indCurFrame), srcPatchPosY(:, indCurFrame), 'cubic', 0);
end

% Reshape to size [pNumPix] x [nCh] x [numPatch]
srcPatch = permute(srcPatch, [1, 3, 2]);

end

function patchRefPosTfmG = apply_affine_tform_patch(A, patchRefPos)

% APPLY_AFFINE_TFORM_PATCH: Apply affine transformation to patch positions in the
% reference frame

numPixPatch = size(patchRefPos, 1);
numPix      = size(A, 1);
A = A';

patchRefPosTfmG        = zeros(numPixPatch, 2, numPix, 'single');
patchRefPosTfmG(:,1,:) = patchRefPos*A([1,3],:);
patchRefPosTfmG(:,2,:) = patchRefPos*A([2,4],:);

end