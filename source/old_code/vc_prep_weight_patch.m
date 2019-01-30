function wPatchS = vc_prep_weight_patch(distMap, trgPixPos, uvTrgRefPos, opt)

[imgH, imgW, nFrame] = size(distMap);
distMap = reshape(distMap, imgH, imgW, 1, nFrame);

% Compute the spatial (distance-based) patch weights
wPatchS  = vc_prep_target_patch(distMap, trgPixPos, uvTrgRefPos);

wPatchS = squeeze(wPatchS);
wPatchS = bsxfun(@minus, wPatchS, wPatchS(opt.pMidPix,:));
% wPatchS = opt.wDist(opt.iLvl).^ wPatchS;

end