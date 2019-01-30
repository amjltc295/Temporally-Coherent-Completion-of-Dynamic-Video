function NNF = vc_init_nnf_lvl(holeMask, videoFlow, NNF, opt)
% VC_INIT_NNF_LVL: Initialize NNF at the current level.
% If the current level is at the coarsest level, then initialize the NNF
% parameters. Otherwise, use the NNF estimated from the previous layer and
% perform nearest neighbor upsampling.
%
% Input:
%  - videoData: video color       - [imgH] x [imgW] x [3] x [nFrame]
%  - videoFlow: fw/bw flow field  - [imgH] x [imgW] x [2] x [nFrame] x [2]
%  - holeMask:  missing regions   - [imgH] x [imgW] x [nFrame]
%  - occMask:   occluded regions  - [imgH] x [imgW] x [nFrame]
%  - NNF:       nearest neighbor field
%  - opt:       algorithm parameters
% Output:
%  - NNF:       initialized nearest neighbor field at the current level
%  - videoData: updated video color
%  - videoFlow: updated video flow

% Mask for invalid flow
invalidFlowFwMask = squeeze(videoFlow(:,:,5,:) < 0.5);
invalidFlowBwMask = squeeze(videoFlow(:,:,6,:) < 0.5);
invalidFlowFwMask(:,:,end) = 0;
invalidFlowBwMask(:,:,1)   = 0;

invalidFlowMask = invalidFlowFwMask | invalidFlowBwMask;
invalidFlowMask(holeMask) = 0;

if(opt.iLvl == opt.numPyrLvl)
    % Patch size
    opt.pSize = 5;                       % 5x5x5 patches
    opt.pRad  = floor(opt.pSize/2);      % Patch radius
    % Initialization at the coarsest level
    NNF = vc_init_nnf(holeMask, invalidFlowMask, opt);
else
    % Patch size
    opt.pSize = 7;                       % 7x7 patches
    opt.pRad  = floor(opt.pSize/2);      % Patch radius
    
    % Upsample NNF from the previous level
    NNF = vc_upsample_NNF(NNF, holeMask, invalidFlowMask, opt);
end

end


% =========================================================================
% Initialize NNF
% =========================================================================

function NNF = vc_init_nnf(holeMask, invalidFlowMask, opt)
% VC_INIT_NNF
%
% Input:
%   - holeMaks: binary mask of size [imgH] x [imgW] x [nFrame]
%   - opt:      algorithm parameters
% Output:
%   - NNF:      initialized nearest neighbor field

% =========================================================================
% Initialize patch positions and indices
% =========================================================================
% Get validSrcPix, holePix, bdPix, and trgPix
[NNF.imgH, NNF.imgW, NNF.nFrame] = size(holeMask);
[NNF.validSrcPix, NNF.holePix, NNF.holePixF, NNF.bdPix, NNF.trgPix] = ...
    vc_get_trgPix(holeMask, opt.pSize, 3);

% Number of target (unknown) pixels
numTrgPix    = NNF.trgPix.numPix;

% Initialize trgPixN and holePixN: spatial neighbors
numNeighbor  = 6;  % spatio-temporal neighbors
NNF.trgPixN  = vc_init_trgPixN(NNF,  opt.propDir, numNeighbor);
NNF.holePixN = vc_init_holePixN(NNF.holePixF, invalidFlowMask, ...
    [NNF.imgH, NNF.imgW, NNF.nFrame], opt.propDir);

% Target and source patch reference position
[X, Y, T] = meshgrid(-opt.pRad:opt.pRad, -opt.pRad:opt.pRad, -opt.pRad:opt.pRad);
NNF.patchRefPos = single(cat(2, X(:), Y(:), T(:)));

% Initialize target patch index (for getting target patches)
NNF.trgPatchInd = vc_prep_patchInd(NNF.trgPix.sub, [NNF.imgH, NNF.imgW, 3, NNF.nFrame], ...
    NNF.patchRefPos);

% =========================================================================
% Initialize variables in the nearest neighbor field
% =========================================================================
% (1) srcPos:   source patch position - (x, y, t) - 3d
% (2) srcTfmG:  geometric transformation - (scale, rotation, shear x, shear y) - 4d

% Initialzie srcPos: source patch positions
initType = 1;
if(initType)
    % Preserving temporal order
    NNF.srcPos.data = zeros(numTrgPix, 3, 'single');
    for indFrame = 1: NNF.nFrame
        indTrgCur = NNF.trgPix.sub(:,3) == indFrame;
        nTrgCur   = sum(indTrgCur);
        if(nTrgCur)
            indSrcCur = find(NNF.validSrcPix.sub(:,3) == indFrame);
            randInd   = randi(size(indSrcCur, 1), nTrgCur, 1);
            NNF.srcPos.data(indTrgCur, :) = NNF.validSrcPix.sub(indSrcCur(randInd),:);
        end
    end
else
    % Random samples
    randInd   = randi(NNF.validSrcPix.numPix, numTrgPix, 1);
    NNF.srcPos.data = NNF.validSrcPix.sub(randInd,:);
end
NNF.srcPos.map  = zeros(NNF.imgH, NNF.imgW, NNF.nFrame, 3, 'single');
uvMapInd = get_uvmap_ind(size(NNF.srcPos.map), NNF.trgPix.ind);
NNF.srcPos.map(uvMapInd) = NNF.srcPos.data;

% Initialzie srcTfmG: source patch transformation
NNF.srcTfmG.data = repmat(single([1, 0, 0, 1]), numTrgPix, 1);
uvMapInd = get_uvmap_ind([NNF.imgH, NNF.imgW, NNF.nFrame, 4], NNF.trgPix.ind);
NNF.srcTfmG.map  = zeros([NNF.imgH, NNF.imgW, NNF.nFrame, 4], 'single');
NNF.srcTfmG.map(uvMapInd) = NNF.srcTfmG.data;

% Initialize with high patch cost
NNF.uvCost = zeros(numTrgPix, 2, 'single');

% =========================================================================
% Spatial weighting for comparing patches
% =========================================================================
[NNF.wPatchM, NNF.wPatchR, NNF.dtMap] = ...
    vc_init_spatial_weight(holeMask, NNF.trgPix.sub, NNF.patchRefPos, 3, opt);

% =========================================================================
% holePatchInd and holePatchMask: for efficient color voting
% =========================================================================
NNF.holePatch =  prep_holePatch(NNF);

end

% =========================================================================
% Upsample NNF from the previous level
% =========================================================================

function NNF = vc_upsample_NNF(NNF_L, holeMask, invalidFlowMask, opt)

fprintf('Upsampling the NNF to the next level: ');

tic;
NNF = [];
[imgH_Hi, imgW_Hi, nFrame] = size(holeMask);

% =========================================================================
% Initialize patch positions and indices
% =========================================================================
% Get validSrcPix, holePix, bdPix, and trgPix
[NNF.imgH, NNF.imgW, NNF.nFrame] = size(holeMask);
[NNF.validSrcPix, NNF.holePix, NNF.holePixF, NNF.bdPix, NNF.trgPix] = ...
    vc_get_trgPix(holeMask, opt.pSize, 2);

% Number of target (unknown) pixels
numTrgPix      = NNF.trgPix.numPix;

% Initialize uvPixN: spatial neighbors
numNeighbor  = 4;  % spatial neighbors
NNF.trgPixN  = vc_init_trgPixN(NNF,  opt.propDir, numNeighbor);
NNF.holePixN = vc_init_holePixN(NNF.holePixF, invalidFlowMask, ...
    [NNF.imgH, NNF.imgW, NNF.nFrame], opt.propDir);

% Target and source patch reference position
[X, Y, T] = meshgrid(-opt.pRad:opt.pRad, -opt.pRad:opt.pRad, 0);
NNF.patchRefPos = single(cat(2, X(:), Y(:), T(:)));

% Initialize target patch index (for getting target patches)
NNF.trgPatchInd = vc_prep_patchInd(NNF.trgPix.sub, [NNF.imgH, NNF.imgW, 3, NNF.nFrame], ...
    NNF.patchRefPos);

% =========================================================================
% Initialize variables in the nearest neighbor field
% =========================================================================
% (1) srcPos:   source patch position - (x, y, t) - 3d
% (2) srcTfmG:  geometric transformation - (scale, rotation) - 2d

% Get correspondense from high-res to low-res
imgH_Lo = NNF_L.imgH;
imgW_Lo = NNF_L.imgW;

sX = imgW_Lo/imgW_Hi;
sY = imgH_Lo/imgH_Hi;

% Corresponding position in the low-res video
trgPixL = vc_get_lowres_pos(NNF.trgPix.sub, [sX, sY], [imgH_Lo, imgW_Lo, nFrame]);

% (1) Initialize srcPos from upsampling
srcPos = vc_uvMat_from_uvMap(NNF_L.srcPos.map,  trgPixL.ind);
srcPos = srcPos*diag([1/sX, 1/sY, 1]);

% (2) Initialzie srcTfmG from upsampling
srcTfmG = vc_uvMat_from_uvMap(NNF_L.srcTfmG.map,  trgPixL.ind);

% Refine srcPos to take into account the subpixel
refineVec = NNF.trgPix.sub(:,1:2) - trgPixL.sub(:,1:2)*diag([1/sX, 1/sY]);
refineVec = vc_apply_affine_tform(srcTfmG, refineVec);

srcPos(:,1:2) = srcPos(:,1:2) + refineVec;

% =========================================================================
% Check if the source patches contain invalid pixels
% =========================================================================
uvValidInd     = vc_check_valid_uv(srcPos, NNF.validSrcPix.mask);
uvInvalidInd   = ~uvValidInd;
if(0)
    nInvalidUv     = sum(uvInvalidInd);
    if(nInvalidUv)
        % Update srcPos
        randInd = randi(size(NNF.validSrcPix.ind, 1), nInvalidUv, 1);
        uvRand  = NNF.validSrcPix.sub(randInd, :);
        srcPos(uvInvalidInd,:) = uvRand;
        
        % Update srcTfmG
        v = single([1,0, 0, 1]);
        srcTfmG(uvInvalidInd,:) = v(ones(nInvalidUv,1),:);
    end
end

% update srcPos
NNF.srcPos.data  = srcPos;
NNF.srcPos.map   = zeros([NNF.imgH, NNF.imgW, NNF.nFrame, 3], 'single');
uvMapInd = get_uvmap_ind(size(NNF.srcPos.map), NNF.trgPix.ind);
NNF.srcPos.map(uvMapInd) = NNF.srcPos.data;

% Update srcTfmG
NNF.srcTfmG.data = srcTfmG;
NNF.srcTfmG.map  = zeros([NNF.imgH, NNF.imgW, NNF.nFrame, 4], 'single');
uvMapInd = get_uvmap_ind([NNF.imgH, NNF.imgW, NNF.nFrame, 4], NNF.trgPix.ind);
NNF.srcTfmG.map(uvMapInd) = NNF.srcTfmG.data;

% Initialize with high patch cost
NNF.uvCost = zeros(numTrgPix, 2, 'single');

% Set high cost for invalid pixels
NNF.uvCost(uvInvalidInd, :) = 1e6;

% =========================================================================
% Spatial weighting for comparing patches
% =========================================================================
% Spatial weighting for comparing patches
[NNF.wPatchM, NNF.wPatchR, NNF.dtMap] = ...
    vc_init_spatial_weight(holeMask, NNF.trgPix.sub, NNF.patchRefPos, 2, opt);

% =========================================================================
% holePatchInd and holePatchMask: for efficient voting (color and flow)
% =========================================================================
NNF.holePatch =  prep_holePatch(NNF);

t = toc;
fprintf('done %.03f seconds \n', t);

end

% =========================================================================
% Utility functions
% =========================================================================

function holePatch = prep_holePatch(NNF)

holePixMap = (NNF.holePix.numPix + 1)*ones(NNF.imgH, NNF.imgW, 1, NNF.nFrame);
holePixMap(NNF.holePix.ind) = 1:NNF.holePix.numPix;
holePatch.ind  = squeeze(vc_prep_target_patch(holePixMap, NNF.trgPix.sub, NNF.patchRefPos));

holePatch.wSum    = zeros(NNF.holePix.numPix + 1, 1, 'single');
for ii = 1: NNF.trgPix.numPix
    patchIndCur  = holePatch.ind(:,ii);
    holePatch.wSum(patchIndCur) = holePatch.wSum(patchIndCur) + ...
        NNF.wPatchR(:,:,ii);
end

end

% function trgPatchInd = vc_prep_patchInd(trgPixPos, videoSize, patchRefPos)
%
% % Prepare target patch position
% pNumPix   = size(patchRefPos, 1);
% numTrgPix = size(trgPixPos, 1);
% nCh       = videoSize(3);
%
% trgPatchPosCenter = reshape(trgPixPos', 1, 3, numTrgPix);
% trgPatchPos = bsxfun(@plus, patchRefPos, trgPatchPosCenter);
%
% % Convert target patch position to index
% trgPatchInd = zeros(pNumPix, nCh, numTrgPix);
% for i = 1: nCh
%     trgPatchInd(:, i, :) = sub2ind(videoSize, ...
%         trgPatchPos(:,2,:), trgPatchPos(:,1,:), ...
%         i*ones(pNumPix, 1, numTrgPix), trgPatchPos(:,3,:));
% end
%
% end

function trgPixL = vc_get_lowres_pos(uvPixSub, scale, videoSize)

trgPixL.sub = zeros(size(uvPixSub), 'single');

trgPixL.sub(:,1) = uvPixSub(:,1)*scale(1);
trgPixL.sub(:,2) = uvPixSub(:,2)*scale(2);
trgPixL.sub(:,3) = uvPixSub(:,3);
trgPixL.sub = round(trgPixL.sub);

trgPixL.ind = sub2ind(videoSize, ...
    trgPixL.sub(:,2), trgPixL.sub(:,1), trgPixL.sub(:,3));

end

function [wPatchM, wPatchR, dtMap] = ...
    vc_init_spatial_weight(holeMask, uvPixSub, uvTrgRefPos, dim, opt)

% wPatchM: patch weights for matching
% wPatchR: patch weights for reconstruction

% =========================================================================
% Compute distance transform
% =========================================================================
holeMaskInv = ~holeMask;
distMap = zeros(size(holeMaskInv), 'single');

if(dim == 2)
    nFrame = size(distMap, 3);
    for i = 1: nFrame
        holeMaskInvCur = holeMaskInv(:,:,i);
        nBdPixel = sum(holeMaskInvCur(:));
        if(nBdPixel == 0)
            distMap(:,:,i) = 1;
        else
            distMap(:,:,i) = bwdist(holeMaskInv(:,:,i), 'euclidean');
        end
    end
elseif(dim == 3)
    distMap = bwdist(holeMaskInv, 'euclidean');
end

patchDist = vc_prep_weight_patch(distMap, uvPixSub, uvTrgRefPos, opt);

% =========================================================================
% wPatchR: patch weights for reconstruction
% =========================================================================
% Higher weights away the boundary
wPatchR = opt.wDist(opt.iLvl).^ patchDist;

% h = fspecial('gaussian', opt.pSize, opt.wSigmaR);

% if(dim == 3)
%     w = h(floor(opt.pSize/2)+1, :);
%     h = h(:,:,ones(opt.pSize,1));
%     h = bsxfun(@times, h, reshape(w, [1,1,opt.pSize]));
%     h = h/sum(h(:));
% end

% wPatchR = bsxfun(@times, wPatchR, h(:));

% =========================================================================
% wPatchM: patch weights for matching
% =========================================================================
h = fspecial('gaussian', opt.pSize, opt.wSigmaM);
if(dim == 3)
    w = h(floor(opt.pSize/2)+1, :);
    h = h(:,:,ones(opt.pSize,1));
    h = bsxfun(@times, h, reshape(w, [1,1,opt.pSize]));
    h = h/sum(h(:));
end

wPatchM = single(h(:));

dtMap = distMap;

end

function wPatchS = vc_prep_weight_patch(distMap, trgPixPos, uvTrgRefPos, opt)

[imgH, imgW, nFrame] = size(distMap);
distMap = reshape(distMap, imgH, imgW, 1, nFrame);

% Compute the spatial (distance-based) patch weights
wPatchS = vc_prep_target_patch(distMap, trgPixPos, uvTrgRefPos);
wPatchS = bsxfun(@minus, wPatchS, wPatchS(opt.pMidPix,1,:));

end

function uvSrcTfm = vc_init_uvSrcTfm(data, uvPix, videoSize)

nDim = size(data, 2);
uvSrcTfm.data = data(ones(uvPix.numPix, 1), :);
uvSrcTfm.map  = zeros(videoSize(1), videoSize(2), videoSize(3), nDim, 'single');
uvSrcTfm.map  = vc_update_uvMap(uvSrcTfm.map, uvSrcTfm.data, uvPix.ind);

end

function valH = vc_get_upsample_value(valL, trgPixLInd, uvPixHiLInd, videoSizeL)

valMapL = zeros([videoSizeL(1), videoSizeL(2), videoSizeL(3), size(valL,2)], 'single');
valMapL = vc_update_uvMap(valMapL, valL, trgPixLInd);
valH    = vc_uvMat_from_uvMap(valMapL, uvPixHiLInd);

end
