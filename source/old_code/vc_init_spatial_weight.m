function [wPatchM, wPatchR, distMap] = vc_init_spatial_weight(holeMask, uvPixSub, uvTrgRefPos, opt)

% wPatchM: patch weights for matching 
% wPatchR: patch weights for reconstruction 

% =========================================================================
% Compute distance transform 
% =========================================================================
holeMaskInv = ~holeMask;
distMap = zeros(size(holeMaskInv), 'single');
for i = 1: size(distMap, 3)
    holeMaskInvCur = holeMaskInv(:,:,i);
    nBdPixel = sum(holeMaskInvCur(:));
    if(nBdPixel == 0)
        distMap(:,:,i) = 1;
    else
        distMap(:,:,i) = bwdist(holeMaskInv(:,:,i), 'euclidean');
    end
end

patchDist = vc_prep_weight_patch(distMap, uvPixSub, uvTrgRefPos, opt);

% =========================================================================
% wPatchM: patch weights for matching 
% =========================================================================
% Higher weights near the boundary
wPatchM = opt.wDist(opt.iLvl).^ (-patchDist);         

h = fspecial('gaussian', opt.pSize, opt.wSigmaM);
h = single(h(:));
wPatchM = bsxfun(@times, wPatchM, h);

wPatchM = bsxfun(@rdivide, wPatchM, sum(wPatchM, 1));

% =========================================================================
% wPatchR: patch weights for reconstruction 
% =========================================================================
% Higher weights away the boundary
wPatchR = opt.wDist(opt.iLvl).^ patchDist;

h = fspecial('gaussian', opt.pSize, opt.wSigmaR);
h = single(h(:));

wPatchR = bsxfun(@times, wPatchR, h);


% if(0)
%     % Positional weight (Gaussian function)
%     h = fspecial('gaussian', opt.pSize, opt.wSigma);
%     wPatchM = h(:);
% else
%     % Uniform weight
%     wPatchM = ones(opt.spPatchSize, 1, 'single');
% end
% Normalize so that the summaztion is one
% wPatchM = wPatchM + eps;
% wPatchM = bsxfun(@rdivide, wPatchM, sum(wPatchM, 1));
% wPatchM = single(wPatchM);


end

function wPatchS = vc_prep_weight_patch(distMap, trgPixPos, uvTrgRefPos, opt)

[imgH, imgW, nFrame] = size(distMap);
distMap = reshape(distMap, imgH, imgW, 1, nFrame);

% Compute the spatial (distance-based) patch weights
wPatchS  = vc_prep_target_patch(distMap, trgPixPos, uvTrgRefPos);

wPatchS = squeeze(wPatchS);
wPatchS = bsxfun(@minus, wPatchS, wPatchS(opt.pMidPix,:));
% wPatchS = opt.wDist(opt.iLvl).^ wPatchS;

end