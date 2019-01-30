function colorData   = vc_voting_color(videoColor, NNF)

% Grab source patch
srcPatch = vc_prep_source_patch(videoColor, NNF.srcPos.data, NNF.srcTfmG.data, NNF.patchRefPos);

% Apply the weighting for the source patch
srcPatch = bsxfun(@times, srcPatch, NNF.wPatchR);

% Voting
colorData  = zeros(NNF.holePix.numPix + 1, size(srcPatch, 2), 'single');
for ii = 1: size(srcPatch, 3)
    indCur = NNF.holePatch.ind(:,ii);
    
    % Counting color votes
    colorData(indCur,:) = colorData(indCur,:) + srcPatch(:,:,ii);
end

% Normalization
colorData = bsxfun(@rdivide, colorData, NNF.holePatch.wSum);
colorData = colorData(1:end-1,:);

end