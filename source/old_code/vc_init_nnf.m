function NNF = vc_init_nnf(holeMask, opt)

% VC_INIT_NNF
%
% =========================================================================
% Initialize uvPix, validPix, and uvPixN
% =========================================================================
[NNF.imgH, NNF.imgW, NNF.nFrame] = size(holeMask);
[NNF.validPix, NNF.uvPix] = vc_get_uvpix(holeMask, opt.pSize);

% === Initialize uvPixN: spatial temporal neighbors ===
NNF.uvPixN = vc_init_uvPixN(NNF, opt);

% =========================================================================
% Target and source patch reference position
% =========================================================================

% Spatial [opt.pSize] x [opt.pSize] x [1] patches
[X, Y, T] = meshgrid(-opt.pRad:opt.pRad, -opt.pRad:opt.pRad, 0);
NNF.uvTrgRefPos = single(cat(2, X(:), Y(:), T(:)));
NNF.uvSrcRefPos = NNF.uvTrgRefPos;

% =========================================================================
% Initialize variables in the nearest neighbor field
% =========================================================================
% (1) uvSrcPos:        source patch position - (x, y, t) - 3d
% (2) uvSrcColorTfmG:  geometric transformation - (scale, rotation) - 2d
% (3) uvSrcColorTfmP:  photometric transformation - bias (dl, du, dv) - 3d
% (4) uvSrcFlowTfrmFw: flow transformation - (s, r, tx, ty) - 4d
% (5) uvSrcFlowTfrmBw: flow transformation - (s, r, tx, ty) - 4d

% (1) Initialize uvSrcPos
randInd = randi(NNF.validPix.numValidPix, NNF.uvPix.numUvPix, 1); % random sampling
NNF.uvSrcPos.data = single(NNF.validPix.sub(randInd, :));

% Initialize uvSrcPos using the nearest valid pixels
if(0)
    [~, nnValidInd] = bwdist(NNF.validPix.mask);
    uvSrcPosInd = nnValidInd(NNF.uvPix.ind);
    [I, J, K] = ind2sub([NNF.imgH, NNF.imgW, NNF.nFrame], uvSrcPosInd);
    NNF.uvSrcPos.data = single(cat(2, J, I, K));
end
NNF.uvSrcPos.map  = zeros(NNF.imgH, NNF.imgW, NNF.nFrame, 3, 'single');
NNF.uvSrcPos.map  = vc_update_uvMap(NNF.uvSrcPos.map, NNF.uvSrcPos.data, NNF.uvPix.ind);

% (2) Initialzie uvSrcColorTfmG: start with identify transformation
NNF.uvSrcTfmG = vc_init_uvSrcTfm(single([1, 0]), NNF.uvPix, [NNF.imgH, NNF.imgW, NNF.nFrame]);

% (3) Initialize uvSrcColorTfmP:  photometric transformation
NNF.uvSrcTfmP = zeros(NNF.uvPix.numUvPix, 3, 'single');

% (4) Initialize uvSrcFlowTfrmFw: forward flow transformation
NNF.uvSrcTfmFw = single([1, 0, 0, 0]);
NNF.uvSrcTfmFw = NNF.uvSrcTfmFw(ones(NNF.uvPix.numUvPix, 1), :);

% (5) Initialize uvSrcFlowTfrmBw: backward flow transformation
NNF.uvSrcTfmBw = NNF.uvSrcTfmFw;

% === Initialize uvCost ===
% Initialize with high patch cost
NNF.uvCost = 1e6*ones(NNF.uvPix.numUvPix, 1, 'single');

% === Initialize updateInd ===
NNF.updateInd = false(NNF.uvPix.numUvPix, 1);

% === Initialize indMap ===
NNF.pixIndMap   = reshape(1:NNF.imgH*NNF.imgW*NNF.nFrame, NNF.imgH, NNF.imgW, 1, NNF.nFrame);
NNF.pixIndMap   = int64(NNF.pixIndMap);
NNF.trgPatchInd = vc_prep_target_patch(single(NNF.pixIndMap), NNF.uvPix.sub, NNF.uvTrgRefPos);
NNF.trgPatchInd = squeeze(NNF.trgPatchInd);

% Spatial weighting for comparing patches
[NNF.wPatchS, NNF.distMap] = vc_init_spatial_weight(holeMask, NNF.uvPix.sub, NNF.uvTrgRefPos, opt);

end


function uvSrcTfm = vc_init_uvSrcTfm(data, uvPix, videoSize)

nDim = size(data, 2);
uvSrcTfm.data = data(ones(uvPix.numUvPix, 1), :);
uvSrcTfm.map  = zeros(videoSize(1), videoSize(2), videoSize(3), nDim, 'single');
uvSrcTfm.map  = vc_update_uvMap(uvSrcTfm.map, uvSrcTfm.data, uvPix.ind);

end

