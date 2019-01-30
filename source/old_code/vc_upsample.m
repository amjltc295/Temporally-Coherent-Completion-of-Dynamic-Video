function NNF = vc_upsample(NNF_L, holeMask, opt)

fprintf('Upsampling the NNF to the next level: ');

tic;
NNF = [];
[imgH_Hi, imgW_Hi, nFrame] = size(holeMask);

% === Initialize uvPix and validPix ===
[NNF.imgH, NNF.imgW, NNF.nFrame] = size(holeMask);
[NNF.validPix, NNF.uvPix] = vc_get_uvpix(holeMask, opt.pSize);

% === Initialize uvPixN: spatial temporal neighbors ===
NNF.uvPixN = vc_init_uvPixN(NNF, opt);

% === Target and source patch reference position ===
% Spatial [opt.pSize] x [opt.pSize] x [1] patches
[X, Y, T] = meshgrid(-opt.pRad:opt.pRad, -opt.pRad:opt.pRad, 0);
NNF.uvTrgRefPos = single(cat(2, X(:), Y(:), T(:)));
NNF.uvSrcRefPos = NNF.uvTrgRefPos;

% === Initialize variables in the nearest neighbor field ===
% (1) uvSrcPos:        source patch position - (x, y, t) - 3d
% (2) uvSrcColorTfmG:  geometric transformation - (scale, rotation) - 2d
% (3) uvSrcColorTfmP:  photometric transformation - bias (dl, du, dv) - 3d
% (4) uvSrcFlowTfrmFw: flow transformation - (s, r, tx, ty) - 4d
% (5) uvSrcFlowTfrmBw: flow transformation - (s, r, tx, ty) - 4d

% Get correspondense from high-res to low-res
imgH_Lo = NNF_L.imgH;
imgW_Lo = NNF_L.imgW;

sX = imgW_Lo/imgW_Hi;
sY = imgH_Lo/imgH_Hi;

% Corresponding position in the low-res video
uvPixL = vc_get_lowres_pos(NNF.uvPix.sub, [sX, sY], [imgH_Lo, imgW_Lo, nFrame], opt);

% (1) Initialize uvSrcPos
% Upsampling
uvSrcPos = vc_uvMat_from_uvMap(NNF_L.uvSrcPos.map,  uvPixL.ind);
uvSrcPos = uvSrcPos*diag([1/sX, 1/sY, 1]);

% (2) Initialzie uvSrcColorTfmG: start with identify transformation
uvSrcTfmG = vc_uvMat_from_uvMap(NNF_L.uvSrcTfmG.map,  uvPixL.ind);

% Refinement
refineVec = NNF.uvPix.sub(:,1:2) - uvPixL.sub(:,1:2)*diag([1/sX, 1/sY]);
sCos = (uvSrcTfmG(:,1).*cos(uvSrcTfmG(:,2)));
sSin = (uvSrcTfmG(:,1).*sin(uvSrcTfmG(:,2)));

refineVecG = zeros(NNF.uvPix.numUvPix, 2, 'single');
refineVecG(:,1) = sum(refineVec.*cat(2, sCos, -sSin), 2);
refineVecG(:,2) = sum(refineVec.*cat(2, sSin,  sCos), 2);

uvSrcPos(:,1:2) = uvSrcPos(:,1:2) + refineVecG;

% Check invalid pixels
srcPatchSample = vc_prep_source_patch(zeros(NNF.imgH, NNF.imgW, 1, NNF.nFrame, 'single'), ...
    uvSrcPos, uvSrcTfmG, NNF.uvSrcRefPos);
srcPatchSample = squeeze(sum(srcPatchSample,1));
uvInvalidInd   = isnan(srcPatchSample);
nInvalidUv     = sum(uvInvalidInd);

if(nInvalidUv)
    % Update uvSrcPos
    randInd = randi(size(NNF.validPix.ind, 1), nInvalidUv, 1);
    uvRand = NNF.validPix.sub(randInd, :);
    uvSrcPos(uvInvalidInd,:) = uvRand;
    
    % Update uvSrcTfmG
    v = single([1,0]);
    uvSrcTfmG(uvInvalidInd,:) = v(ones(nInvalidUv,1),:);
end

% update uvSrcPos
NNF.uvSrcPos.data = uvSrcPos;
NNF.uvSrcPos.map  = zeros(NNF.imgH, NNF.imgW, NNF.nFrame, 3, 'single');
NNF.uvSrcPos.map  = vc_update_uvMap(NNF.uvSrcPos.map, NNF.uvSrcPos.data, NNF.uvPix.ind);

% Update uvSrcTfmG
NNF.uvSrcTfmG.data = uvSrcTfmG;
NNF.uvSrcTfmG.map  = zeros(NNF.imgH, NNF.imgW, NNF.nFrame, 2, 'single');
NNF.uvSrcTfmG.map  = vc_update_uvMap(NNF.uvSrcTfmG.map, NNF.uvSrcTfmG.data, NNF.uvPix.ind);

% (3) Initialize uvSrcColorTfmP:  photometric transformation
videoSizeL = [NNF_L.imgH, NNF_L.imgW, NNF_L.nFrame];
uvSrcTfmP = squeeze(NNF_L.uvSrcTfmP)';

uvSrcTfmP = vc_get_upsample_value(uvSrcTfmP, NNF_L.uvPix.ind, uvPixL.ind, videoSizeL);
NNF.uvSrcTfmP = reshape(uvSrcTfmP', [1, 3, NNF.uvPix.numUvPix]);

% (4) Initialize uvSrcFlowTfrmFw: forward flow transformation
NNF.uvSrcTfmFw = vc_get_upsample_value(NNF_L.uvSrcTfmFw, NNF_L.uvPix.ind, uvPixL.ind, videoSizeL);

% (5) Initialize uvSrcFlowTfrmBw: backward flow transformation
NNF.uvSrcTfmBw = vc_get_upsample_value(NNF_L.uvSrcTfmBw, NNF_L.uvPix.ind, uvPixL.ind, videoSizeL);

% === Initialize uvCost ===
% Initialize with high patch cost
NNF.uvCost = vc_get_upsample_value(NNF_L.uvCost, NNF_L.uvPix.ind, uvPixL.ind, videoSizeL);

% === Initialize updateInd ===
NNF.updateInd = false(NNF.uvPix.numUvPix, 1);

% === Initialize indMap ===
NNF.pixIndMap = reshape(1:NNF.imgH*NNF.imgW*NNF.nFrame, NNF.imgH, NNF.imgW, 1, NNF.nFrame);
NNF.pixIndMap = int64(NNF.pixIndMap);
NNF.trgPatchInd = vc_prep_target_patch(single(NNF.pixIndMap), NNF.uvPix.sub, NNF.uvTrgRefPos);
NNF.trgPatchInd = squeeze(NNF.trgPatchInd);

% Spatial weighting for comparing patches
[NNF.wPatchS, NNF.distMap] = vc_init_spatial_weight(holeMask, NNF.uvPix.sub, NNF.uvTrgRefPos, opt);

t = toc;
fprintf('done %.03f seconds \n', t);

end

function valH = vc_get_upsample_value(valL, uvPixLInd, uvPixHiLInd, videoSizeL)

valMapL = zeros([videoSizeL(1), videoSizeL(2), videoSizeL(3), size(valL,2)], 'single');
valMapL = vc_update_uvMap(valMapL, valL, uvPixLInd);
valH    = vc_uvMat_from_uvMap(valMapL, uvPixHiLInd);

end

function uvPixL = vc_get_lowres_pos(uvPixSub, scale, videoSize, opt)

uvPixL.sub = zeros(size(uvPixSub), 'single');

uvPixL.sub(:,1) = uvPixSub(:,1)*scale(1);
uvPixL.sub(:,2) = uvPixSub(:,2)*scale(2);
uvPixL.sub(:,3) = uvPixSub(:,3);
uvPixL.sub = round(uvPixL.sub);
uvPixL.sub(:,1) = vc_clamp(uvPixL.sub(:,1), opt.pRad + 1, videoSize(2) - opt.pRad);
uvPixL.sub(:,2) = vc_clamp(uvPixL.sub(:,2), opt.pRad + 1, videoSize(1) - opt.pRad);

uvPixL.ind = sub2ind(videoSize, ...
    uvPixL.sub(:,2), uvPixL.sub(:,1), uvPixL.sub(:,3));

end

