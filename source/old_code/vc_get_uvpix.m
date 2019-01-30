function [validPix, uvPix] = vc_get_uvpix(holeMask, psize)
% VC_GET_UVPIX
%
% Given the missgin regions, get the pixel positions where the patches of
% size psize contains at least one unkonwn pixel
%
% Input:
%   - holeMask: unknown regions
%   - psize:    patch size (odd number, usually 5 or 7)
% Output:
%   - validPix: the center positions of patches that contain known values
%   - uvPix:    the center positions of patches that contain at least one
%               unknown value

% Get uvMap from holeMask
uvMap = getUvMap(holeMask, psize);

% Get uvPix
uvPix = getUvPix(uvMap);

% Get validPix
validPix = getValidPix(uvMap, psize);


end

function validPix = getValidPix(uvMap, psize)

prad = floor(psize/2);
[imgH, imgW, nFrame] = size(uvMap);

validMap = ~uvMap;
% Remove border pixels
validMap([1:prad, end-prad+1:end], :, :) = 0;
validMap(:,  [1:prad, end-prad+1:end], :) = 0;

% Get validPix format in ind, sub, mask
validPix.mask = validMap;
validPix.ind = int64(find(validMap));
validPix.numValidPix = size(validPix.ind, 1);

validPix.sub = zeros(validPix.numValidPix, 3, 'single');
[validPix.sub(:,2), validPix.sub(:,1), validPix.sub(:,3)]  = ...
    ind2sub([imgH, imgW, nFrame], validPix.ind);

end

function uvPix = getUvPix(uvMap)

% Get uvPix format in ind, sub, mask
[imgH, imgW, nFrame] = size(uvMap);

uvPix.mask = uvMap;
uvPix.ind = int64(find(uvMap));
uvPix.numPix = size(uvPix.ind, 1);

uvPix.sub = zeros(uvPix.numPix, 3, 'single');
[uvPix.sub(:,2), uvPix.sub(:,1), uvPix.sub(:,3)]  = ...
    ind2sub([imgH, imgW, nFrame], uvPix.ind);

% bdInd: 1: first frame of the sequence
%        2: the end of the sequence
uvPix.bdInd = zeros(uvPix.numPix, 1, 'uint8');
uvPix.bdInd(uvPix.sub(:,3) == 1)      = 1;
uvPix.bdInd(uvPix.sub(:,3) == nFrame) = 2;

% Indices for getting color values
uvPix.indC = zeros(uvPix.numPix, 3, 'int64');
for i = 1: 3
    uvPix.indC(:,i) = sub2ind([imgH, imgW, 3, nFrame], ...
        uvPix.sub(:,2), uvPix.sub(:,1), i*ones(uvPix.numPix, 1), uvPix.sub(:,3));
end

% Indices for getting flow values
uvPix.indF = zeros(uvPix.numPix, 2, 'int64');
for i = 1: 2
    uvPix.indF(:,i) = sub2ind([imgH, imgW, 2, nFrame], ...
        uvPix.sub(:,2), uvPix.sub(:,1), i*ones(uvPix.numPix, 1), uvPix.sub(:,3));
end

end

function uvMap = getUvMap(holeMask, psize)

% Dilate the holeMask by a square of size psize x psize
seSquare = strel('square', double(psize));
uvMap = imdilate(holeMask, seSquare);

% Remove border pixels
prad = floor(psize/2);
uvMap([1:prad, end-prad+1:end], :, :) = 0;
uvMap(:, [1:prad, end-prad+1:end], :) = 0;

end