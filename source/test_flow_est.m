function videoFlow = test_flow_est(videoColor, videoFlow, holeMask, opt)

% Preprocessing
minF = min(videoFlow(:));
maxF = max(videoFlow(:));

figure(1); imagesc(videoFlow(:,:,1,1), [minF, maxF]); colorbar;
videoFlow(:) = 0.8*videoFlow(:);

[imgH, imgW, ~, nFrame] = size(videoColor);

% === Prepare invalidFlowFwMask ===
invalidFlowFwMask = squeeze(videoFlow(:,:,5,:) < 0.5);
invalidFlowBwMask = squeeze(videoFlow(:,:,6,:) < 0.5);
invalidFlowFwMask(:,:,end) = 0;
invalidFlowBwMask(:,:,1)   = 0;

invalidFlowMask = invalidFlowFwMask | invalidFlowBwMask;
invalidFlowMask(logical(holeMask)) = 0;

% === Prepare holePix ===
holePix  = getUvPix(holeMask);

% === Prepare holePixF ===
holePixF = getUvPix(imdilate(holeMask, strel('disk', 2)));
% holePixF.indS: convert holePixF indices to holePix
videoInd = zeros(size(holeMask), 'single');
videoInd(holePixF.ind) = 1:holePixF.numPix;
holePixF.indS = videoInd(holePix.ind);
% holePixF.indB: the border index of holePixF (for enforcing boundary constraints)
videoInd(:) = 0;
videoInd(holePix.ind) = 1:holePix.numPix;
holePixF.indB = videoInd(holePixF.ind) == 0;

% === Prepare holePixN ===
holePixN = vc_init_holePixN(holePixF, invalidFlowMask, [imgH, imgW, nFrame], opt.propDir);

% Update flow
[flowDataF, flowDataB] = vc_update_flow(videoColor, videoFlow, holePixF, holePixN);

videoFlow(holePix.indFt(:,:,1)) = flowDataF;      % Update forward flow
videoFlow(holePix.indFt(:,:,2)) = flowDataB;      % Update backward flow

% Visualize results

figure(2); imagesc(videoFlow(:,:,1,1), [minF, maxF]); colorbar;

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
