function vc_vis_nnf(NNF, iter, opt)

% VC_VIS_NNF: visualize nearest neighbor field
% Input:
%   - NNF:  the estimated nearest neighbor
%   - iter: current iteration number
%   - opt:  algorithm parameters

videoSize = [NNF.imgH, NNF.imgW, NNF.nFrame];

% The boundary of the hole
bdMask = imdilate(NNF.trgPix.mask, strel('square', 3));
bdMask = xor(bdMask, NNF.trgPix.mask);

% Visualize uvSrcPos, uvSrcTfmG, uvSrcTfmP
[uvSrcPosXYVis, uvSrcPosTVis] = vis_uvSrcPos(NNF.srcPos.map,  NNF.trgPix.mask, bdMask);

% uvOffset = NNF.srcPos.data - NNF.trgPix.sub;
% uvOffsetVis = vis_uvOffset(uvOffset,  NNF.trgPix, bdMask);

% Visualize uvCost
uvCostVis = vis_uvCost(NNF.uvCost, NNF.trgPix.ind, videoSize, NNF.trgPix.mask, bdMask);

% Visualize scaling
% uvSrcScaleVis = vis_uvSrcScale(NNF.srcTfmG.data, NNF.trgPix.ind, videoSize, NNF.trgPix.mask, bdMask);

% Visualize bias
% uvSrcBiasVis = vis_uvSrcBias(NNF.srcTfmP, NNF.trgPix.ind, videoSize, NNF.trgPix.mask, bdMask);

% Visualize
% uvSrcTfmPVis = vis_uvSrcTfmP(NNF.uvSrcTfmP, NNF.uvPix.ind, [NNF.imgH, NNF.imgW, NNF.nFrame], NNF.uvPix.mask);

export_nnf_vis(uvSrcPosXYVis, 'uvXY', iter, opt);
export_nnf_vis(uvSrcPosTVis,  'uvT',  iter, opt);

% export_nnf_vis(uvOffsetVis,  'uvOffset',  iter, opt);
export_nnf_vis(uvCostVis,     'uvCost',     iter, opt);
% export_nnf_vis(uvSrcScaleVis, 'uvScale',   iter, opt);

end

function export_nnf_vis(uvMapVis, fileType, iter, opt)

% Specify image path
imgPath = fullfile(opt.visResPath, ['level', num2str(opt.iLvl)]);
if(~exist(imgPath, 'dir'))
    mkdir(imgPath);
end

% Write image results
nFrame = size(uvMapVis, 4);
for i = 1: nFrame
    imgName = [opt.videoName, '_', fileType, '_', num2str(i, '%03d'), '_iter_' num2str(iter, '%03d'), '.png'];
    imwrite(uvMapVis(:,:,:,i), fullfile(imgPath, imgName));
end

end

% function uvSrcTfmPVis = vis_uvSrcTfmP(uvSrcTfmP, uvPixInd, sizeVideo, mask)
%
% nFrame = sizeVideo(3);
% uvSrcTfmLVis = zeros(sizeVideo(1), sizeVideo(2), 1, sizeVideo(3));
% uvSrcTfmAVis = zeros(sizeVideo(1), sizeVideo(2), 1, sizeVideo(3));
% uvSrcTfmBVis = zeros(sizeVideo(1), sizeVideo(2), 1, sizeVideo(3));
%
% end


function uvSrcBiasVis = vis_uvSrcBias(uvSrcTfmP, uvPixInd, sizeVideo, holeMask, bdMask)
% TO-DO: NEED TO TRANSFORM BETWEEN LAB and RGB

uvSrcBiasVis = zeros(sizeVideo(1), sizeVideo(2), 3, sizeVideo(3));

uvSrcTfmP = squeeze(uvSrcTfmP);
uvSrcBiasVis(uvPixInd) = uvSrcTfmP;

end

function uvScaleVis = vis_uvSrcScale(uvSrcTfmG, uvPixInd, sizeVideo, holeMask, bdMask)

% Visualize scale

uvSrcScale = uvSrcTfmG(:,1).*uvSrcTfmG(:,4) - uvSrcTfmG(:,2).*uvSrcTfmG(:,3);
uvSrcScale = abs(uvSrcScale);

nFrame = sizeVideo(3);
uvSrcScaleMap = zeros(sizeVideo);
uvSrcScaleMap(uvPixInd) = uvSrcScale;

% Make the holeMask and bdMask as three-channel mask
holeMask = makeMaskCh(holeMask, 3);
bdMask   = makeMaskCh(bdMask, 3);

uvScaleVis = zeros(sizeVideo(1), sizeVideo(2), 3, sizeVideo(3));
% cmap = jet(256);

for i = 1: nFrame
    
    imgVis = uvSrcScaleMap(:,:,i);
    imgVis = 2*(imgVis - 1) + 0.5;
    imgVis = imgVis(:,:,ones(3,1));
    
    % uv mask and boundary mask
    maskCur   = holeMask(:,:,:,i);
    bdMaskCur = bdMask(:,:,:,i);
    
    imgVis(~maskCur)  = 0.5;
    imgVis(bdMaskCur) = 1;
%     imgVis = ind2rgb(gray2ind(imgVis, 256), cmap);
    
    uvScaleVis(:,:,:,i) = imgVis;
end

end

function uvCostVis = vis_uvCost(uvCost, uvPixInd, sizeVideo, holeMask, bdMask)

% Get uvCostMap

uvCost = uvCost(:,1);
% uvCost = uvCost(:,2);

uvCostMap = zeros(sizeVideo);
if(~isempty(uvCost))
    uvCostMap(uvPixInd) = uvCost;
    uvCostMap = uvCostMap/max(uvCost(:));
end

% Make the holeMask and bdMask as three-channel mask
holeMask = makeMaskCh(holeMask, 3);
bdMask   = makeMaskCh(bdMask, 3);

uvCostVis = zeros(sizeVideo(1), sizeVideo(2), 3, sizeVideo(3));
cmap = jet(256);

for i = 1: sizeVideo(3)
    uvCostCur = uvCostMap(:,:,i);
    
    % uv mask and boundary mask
    maskCur = holeMask(:,:,:,i);
    bdMaskCur = bdMask(:,:,:,i);
    
    % Visualizing cost
    uvCostCur = ind2rgb(gray2ind(uvCostCur, 256), cmap);
    
    uvCostCur(~maskCur) = 0.5;
    uvCostCur(bdMaskCur) = 1;
    uvCostVis(:,:,:,i) = uvCostCur;
end

end


function [uvOffsetVis] = vis_uvOffset(uvOffset,  trgPix, bdMask)

[imgH, imgW, nFrame] = size(bdMask);

% Visualize offset
uvOffset(:,1) = (uvOffset(:,1) + imgW)/(2*imgW);
uvOffset(:,2) = (uvOffset(:,2) + imgH)/(2*imgH);
uvOffset(:,3) = uvOffset(:,3)/nFrame;

% 
uvOffsetMap = 0.5*ones(imgH, imgW, nFrame, 3, 'single');
uvOffsetMap = vc_update_uvMap(uvOffsetMap,  uvOffset,  trgPix.ind);

% 
uvOffsetVis = zeros(imgH, imgW, 3, nFrame, 'single');
bdMask   = makeMaskCh(bdMask, 3);

for i = 1: nFrame
    % Visualize the XY position
    uvOffsetMapCur = squeeze(uvOffsetMap(:,:,i,:));
    
    % Get boundary mask
    bdMaskCur = bdMask(:,:,:,i);
    uvOffsetMapCur(bdMaskCur) = 1;
    
    uvOffsetVis(:,:,:,i) = uvOffsetMapCur;
end

end

function [uvSrcPosXYVis, uvSrcPosTVis] = vis_uvSrcPos(uvSrcPosMap, holeMask, bdMask)
% Visualize the source patch (x, y, t) positions

[imgH, imgW, nFrame, ~] = size(uvSrcPosMap);

% Get srcPosMap
[X, Y] = meshgrid(1:imgW, 1:imgH);
srcPosMap = zeros(imgH, imgW, 3);
srcPosMap(:,:,2) = 0.5;
srcPosMap(:,:,1) = X/imgW;
srcPosMap(:,:,3) = Y/imgH;

uvSrcPosMap(:,:,:,3) = uvSrcPosMap(:,:,:,3)/nFrame;

uvSrcPosXYVis = srcPosMap(:,:,:,ones(nFrame, 1));
uvSrcPosTVis  = zeros(imgH, imgW, 3, nFrame);

cmap = jet(256);

% Make the holeMask and bdMask as three-channel mask
holeMask = makeMaskCh(holeMask, 3);
bdMask   = makeMaskCh(bdMask, 3);

for i = 1: nFrame
    % Visualize the XY position
    imgVisXY = zeros(imgH, imgW, 3);
    imgVisXY(:,:,2) = 0.5;
    imgVisXY(:,:,1) = (uvSrcPosMap(:,:,i,1))/imgW;
    imgVisXY(:,:,3) = (uvSrcPosMap(:,:,i,2))/imgH;
    
    % Get hole mask and boundary mask
    maskCur   = holeMask(:,:,:,i);
    bdMaskCur = bdMask(:,:,:,i);
    
    % Visualize XY map
    imgVisXY = srcPosMap.*(1-maskCur) + imgVisXY.*maskCur;
    imgVisXY(bdMaskCur) = 1;
    uvSrcPosXYVis(:,:,:,i) = imgVisXY;
    
    % Visualize the time index
    imgVisT = uvSrcPosMap(:,:,i,3);
    imgVisT = ind2rgb(gray2ind(imgVisT, 256), cmap);
    imgVisT(~maskCur) = 0.5;
    imgVisT(bdMaskCur) = 1;
    uvSrcPosTVis(:,:,:,i) = imgVisT;
end

end


function x = makeMaskCh(x, nCh)

[imgH, imgW, nFrame] = size(x);
x = reshape(x, [imgH, imgW, 1, nFrame]);
x = x(:,:,ones(nCh, 1), :);

end