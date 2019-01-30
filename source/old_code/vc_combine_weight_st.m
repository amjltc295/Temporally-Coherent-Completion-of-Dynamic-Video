function wPatchST = vc_combine_weight_st(wPatchS, wPatchT, opt)

numUvPix = size(wPatchS, 2);

% Reshape spatial weight
if(opt.flowFlag)
    wPatchS = reshape(wPatchS, [opt.spPatchSize, 1, 1, numUvPix]);
else
    wPatchS = reshape(wPatchS, [opt.spPatchSize, opt.nFrame, 1, size(wPatchS,2)]);
end
% Reshape temporal weight
wPatchT = reshape(wPatchT, [1, opt.nFrame, 1, 1]);

% Combine both weights
wPatchST = bsxfun(@times, wPatchS, wPatchT);

end
