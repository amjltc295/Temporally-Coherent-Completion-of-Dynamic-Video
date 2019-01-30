function [validSrcPix, holePix, holePixF, bdPix, trgPix] = vc_get_trgPix(holeMask, psize, dim)
% VC_GET_TRGPIX: Given the missgin regions, get the pixel positions where the patches of
% size psize contains at least one unkonwn pixel
%
% Input:
%   - holeMask: unknown regions
%   - psize:    patch size (odd number, usually 5 or 7)
% Output:
%   - validPix: the center positions of patches that contain known values
%   - uvPix:    the center positions of patches that contain at least one
%               unknown value


% trgPix: patches that overlap with hole
uvMask  = getUvMap(holeMask, psize, dim);
trgPix  = getUvPix(uvMask);

% holePix: unknown pixels
holePix = getUvPix(holeMask);

% validSrcPix: patches that are known pixels
validSrcPix = getValidPix(uvMask, psize, dim);

% Get holePixF: unknown pixels for computing optical flow
holePixF = getUvPix(imdilate(holeMask, strel('disk', 2)));

% holePixF.indS: convert holePixF indices to holePix
videoInd = zeros(size(holeMask), 'single');
videoInd(holePixF.ind) = 1:holePixF.numPix;
holePixF.indS = videoInd(holePix.ind);

% holePixF.indB: the border index of holePixF (for enforcing boundary constraints)
videoInd(:) = 0;
videoInd(holePix.ind) = 1:holePix.numPix;
holePixF.indB = videoInd(holePixF.ind) == 0;

% bdPix: border pixels (for predictive bias compensation)
holeMaskD = imdilate(holeMask, strel('disk', 1));
bdMask    = xor(holeMaskD, holeMask);
bdPix     = getUvPix(bdMask);

end

function uvMap = getUvMap(holeMask, psize, dim)

prad = floor(psize/2);

% Get uvMap by dilating the holeMask with a square patch of size psize
if(dim == 2)
    seSquare = strel('square', double(psize));
    uvMap    = imdilate(holeMask, seSquare);

    % Remove border pixels
    uvMap([1:prad, end-prad+1:end], :, :) = 0;
    uvMap(:, [1:prad, end-prad+1:end], :) = 0;
elseif(dim == 3)
    uvMap    = imdilate(holeMask, ones(psize,psize,psize));
    uvMap([1:prad, end-prad+1:end], :, :) = 0;
    uvMap(:, [1:prad, end-prad+1:end], :) = 0;
    uvMap(:, :, [1:prad, end-prad+1:end]) = 0;
end

end

function uvPix = getUvPix(uvMap)

% Get uvPix format in ind, sub, mask format
[imgH, imgW, nFrame] = size(uvMap);

uvPix.mask   = uvMap;
uvPix.ind    = int64(find(uvMap));
uvPix.numPix = size(uvPix.ind, 1);

uvPix.indMap = zeros(size(uvMap), 'int64');
uvPix.indMap(uvPix.ind) = 1: uvPix.numPix;

numUvPix     = uvPix.numPix;

uvPix.sub = zeros(numUvPix, 3, 'single');
[uvPix.sub(:,2), uvPix.sub(:,1), uvPix.sub(:,3)]  = ...
    ind2sub([imgH, imgW, nFrame], uvPix.ind);

% Indices for getting color values
uvPix.indC = zeros(uvPix.numPix, 3, 'int64');
for iCh = 1: 3
    uvPix.indC(:,iCh) = sub2ind([imgH, imgW, 3, nFrame], ...
        uvPix.sub(:,2), uvPix.sub(:,1), iCh*ones(numUvPix, 1, 'single'), uvPix.sub(:,3));
end

% Indices for getting flow values from [x, y] channels
uvPix.indF = zeros(uvPix.numPix, 2, 'int64');
nCh   = 2;
for iCh = 1: nCh
    uvPix.indF(:,iCh) = sub2ind([imgH, imgW, nCh, nFrame], ...
        uvPix.sub(:,2), uvPix.sub(:,1), ...
        iCh*ones(numUvPix, 1, 'single'), uvPix.sub(:,3));
end

% Indices for getting flow values
uvPix.indFt = zeros(uvPix.numPix, 2, 3, 'int64');
nFlow = 3;
nCh   = 2;

for iFlow = 1:nFlow
    for iCh = 1: nCh
        uvPix.indFt(:,iCh,iFlow) = sub2ind([imgH, imgW, nCh*nFlow, nFrame], ...
            uvPix.sub(:,2), uvPix.sub(:,1), ...
            (iCh + (iFlow-1)*nCh)*ones(numUvPix, 1, 'single'), uvPix.sub(:,3));
    end
end

end

function validPix = getValidPix(uvMap, psize, dim)

prad = floor(psize/2);
[imgH, imgW, nFrame] = size(uvMap);

validMap = ~uvMap;

% Remove border pixels
validMap([1:prad, end-prad+1:end], :, :) = 0;
validMap(:,  [1:prad, end-prad+1:end], :) = 0;
if(dim == 3) % For spatio-temporal patches
    validMap(:, :, [1:prad, end-prad+1:end]) = 0;
end

% Get validPix format in ind, sub, mask
validPix.mask   = validMap;
validPix.ind    = int64(find(validMap));
validPix.numPix = size(validPix.ind, 1);

validPix.sub = zeros(validPix.numPix, 3, 'single');
[validPix.sub(:,2), validPix.sub(:,1), validPix.sub(:,3)]  = ...
    ind2sub([imgH, imgW, nFrame], validPix.ind);

end