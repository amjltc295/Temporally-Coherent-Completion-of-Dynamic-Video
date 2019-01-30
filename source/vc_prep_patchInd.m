function trgPatchInd = vc_prep_patchInd(pixPos, videoSize, patchRefPos)

% Prepare target patch position
pNumPix   = size(patchRefPos, 1);
numTrgPix = size(pixPos, 1);
nCh       = videoSize(3);

trgPatchPosCenter = reshape(pixPos', 1, 3, numTrgPix);
trgPatchPos = bsxfun(@plus, patchRefPos, trgPatchPosCenter);

% Convert target patch position to index
trgPatchInd = zeros(pNumPix, nCh, numTrgPix);
for i = 1: nCh
    trgPatchInd(:, i, :) = sub2ind(videoSize, ...
        trgPatchPos(:,2,:), trgPatchPos(:,1,:), ...
        i*ones(pNumPix, 1, numTrgPix), trgPatchPos(:,3,:));
end

end
