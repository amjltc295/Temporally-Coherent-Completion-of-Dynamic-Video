% =========================================================================
% Color update
% =========================================================================

function colorDataCur = vc_update_color(videoColor, videoFlow, NNF, colorData, ...
    indFrame, uvValidCur, weightT, trgPixSubT, opt)

% VC_UPDATE_COLOR: update color by combining spatial patch synthesis and tempoal diffusion
% =========================================================================
% Gauss–Seidel method for the solving flow-constrained linear system
% =========================================================================
interpolationKernel = 'linear';

fwWeight    = weightT.fw;
bwWeight    = weightT.bw;
trgPixSubFw = trgPixSubT.fw;
trgPixSubBw = trgPixSubT.bw;

% Spatial color data term
colorDataCur  = opt.wSpPatch*colorData(uvValidCur,:);   % Spatially voted color
combWeightCur = opt.wSpPatch;

% 1. === Forward flow for backward diffusion ===
trgPixSubFwCur = trgPixSubFw(uvValidCur,:); % Forward  flow neighbor position
fwWeightCur    = fwWeight(uvValidCur);      % Forward  flow weights
colorDataFw    = vc_interp3(videoColor, trgPixSubFwCur, interpolationKernel); % Colors of flow neighbors
if(opt.usePredBiasMap)  % Predictive bias map for backward flow
    colorOffset = vc_pred_bias_field(videoColor, videoFlow, ...
        NNF.bdPix, NNF.holePix, occMask, uvValidCur, indFrame, 'forward', opt);
    colorDataFw = colorDataFw + colorOffset;
end
% Update the color at the current frame
colorDataCur  = colorDataCur  + bsxfun(@times, fwWeightCur, colorDataFw);
combWeightCur = combWeightCur + fwWeightCur;

% 2.  === Backward flow for backward diffusion ===
trgPixSubBwCur = trgPixSubBw(uvValidCur,:); % Backward  flow neighbor position
bwWeightCur    = bwWeight(uvValidCur);      % Backward  flow weights
colorDataBw    = vc_interp3(videoColor, trgPixSubBwCur, interpolationKernel); % Colors of flow neighbors
if(opt.usePredBiasMap)  % Predictive bias map for backward flow
    colorOffset = vc_pred_bias_field(videoColor, videoFlow, ...
        NNF.bdPix, NNF.holePix, uvValidCur, indFrame, 'backward', opt);
    colorDataBw = colorDataBw + colorOffset;
end
% Update the color at the current frame
colorDataCur  = colorDataCur  + bsxfun(@times, bwWeightCur, colorDataBw);
combWeightCur = combWeightCur + bwWeightCur;

% Update the color estimation
colorDataCur  = bsxfun(@rdivide, colorDataCur, combWeightCur);

end

function colorOffset = vc_pred_bias_field(videoData, videoFlow, ...
    bdPix, holePix, uvValidCur, frameCur, direction, opt)

% Estimate the bias offset at the border pixels and propagate into the hole

[imgH, imgW, nCh, nFrame] = size(videoData);

bdPixIndCur = bdPix.sub(:,3) == frameCur;
if(opt.useGtOccMask)
    occLabel = occMask(bdPix.ind(bdPixIndCur));
end
% =========================================================================
% Estimate bias at border pixels
% =========================================================================
if(strcmp(direction, 'forward'))
    flowInd = 1;
    frameInc = 1;
    bdInd   = 2;
elseif(strcmp(direction, 'backward'))
    flowInd = 2;
    frameInc = -1;
    bdInd   = 1;
else
    error('frameInc must be either 1 or -1');
end

% Get the flow neighbors of boundary pixels
bdPixFlowNSub = vc_get_flow_neightbor(videoFlow(:,:,:,:,flowInd), ...
    bdPix.indF(bdPixIndCur,:,1), bdPix.sub(bdPixIndCur,:), frameInc);

% Check if the flow neighbors are valid
flowNValidInd = vc_check_index_limit(bdPixFlowNSub, [imgW, imgH, nFrame]) & ...
    (bdPix.bdInd(bdPixIndCur) ~= bdInd);
if(opt.useGtOccMask)
    flowNValidInd = flowNValidInd & (~occLabel);
end
bdPixIndCur(bdPixIndCur) = flowNValidInd;

% Get color of the border pixels
colorBd = videoData(bdPix.indC(bdPixIndCur, :));

% Get color of the flow neighbors of border pixels
colorBdFlowN = vc_interp3(videoData, bdPixFlowNSub(flowNValidInd, :));

% Compute temporal color offset
colorOffsetBd = colorBd - colorBdFlowN;
colorOffsetBd = vc_clamp(colorOffsetBd, opt.minBias, opt.maxBias);

% =========================================================================
% Smoothly intepolate the region
% =========================================================================

imgBias = zeros(imgH, imgW, nCh, 'single');
bdPixValidSub = bdPix.sub(bdPixIndCur,:);
bdPixValidInd = sub2ind([imgH, imgW], bdPixValidSub(:,2), bdPixValidSub(:,1));
bdPixValidInd = bsxfun(@plus, bdPixValidInd, (0:2)*imgH*imgW);

imgBias(bdPixValidInd) = colorOffsetBd;

% Interpolate each channel
for iCh = 1: nCh
    imgBias(:,:,iCh) = ...
        regionfill(imgBias(:,:,iCh), holePix.mask(:,:,frameCur));
end

% =========================================================================
% Convert it to vector form
% =========================================================================
holePixSub = holePix.sub(uvValidCur,:);
holePixInd = sub2ind([imgH, imgW], holePixSub(:,2), holePixSub(:,1));
holePixInd = bsxfun(@plus, holePixInd, (0:2)*imgH*imgW);

colorOffset = imgBias(holePixInd);

end


