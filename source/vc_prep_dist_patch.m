function [wDistPath, wCenterPatch, wDistSum] = vc_prep_weight_patch(distMap, trgPixPos, iLvl, uvTrgRefPos, opt)


%%

%%
[imgH, imgW, nFrame] = size(distMap);
distMap = reshape(distMap, imgH, imgW, 1, nFrame);
% Compute the patch weights
wDistPatch  = vc_prep_target_patch(distMap, trgPixPos, uvTrgRefPos);
wDistPatch = squeeze(wDistPatch);
wDistPatch = bsxfun(@minus, wDistPatch, wDistPatch(opt.pMidPix,:));
wDistPatch  = opt.wDist(iLvl).^ (- wDistPatch); 

% Center weighted (Gaussian) for matching patches
wCenterPatch = fspecial3('gaussian', opt.pSize);

% Sum of the patch weights for all unknown pixels
numUvPix = size(wDistPatch, 2);

wDistSum = zeros(imgH, imgW, nFrame);
indMap = reshape(1:imgH*imgW*nFrame, imgH, imgW, 1, nFrame);
indPatch  = vc_prep_target_patch(indMap, trgPixPos, uvTrgRefPos);
indPatch = squeeze(indPatch);

for i = 1: numUvPix
    wDistSum(indPatch(:,i)) = wDistSum(indPatch(:,i)) ...
        + wDistPatch(opt.pMidPix, i);
end

end