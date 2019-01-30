function [fwWeight, bwWeight, trgPixSubFw, trgPixSubBw] = ...
    vc_get_color_temp_weight(videoFlow, videoData, holePix, distMap, opt)

[imgH, imgW, ~, nFrame, ~] = size(videoFlow);

% ========================================================================================
% Initialization
% ========================================================================================
flowIndFw = 1:2;
flowIndBw = 3:4;

[videoFlowF, videoFlowB] = deal(videoFlow(:,:,flowIndFw,:), videoFlow(:,:,flowIndBw,:));

% Weight initialization
fwWeight = zeros(holePix.numPix, 1, 'single');
bwWeight = zeros(holePix.numPix, 1, 'single');

% Get flow neighbors
trgPixSubFw = vc_get_flow_neightbor(videoFlowF, holePix.indF, holePix.sub,  1);
trgPixSubBw = vc_get_flow_neightbor(videoFlowB, holePix.indF, holePix.sub, -1);

% Get valid indices
validIndFw = vc_check_index_limit(trgPixSubFw, [imgW, imgH, nFrame]);
validIndBw = vc_check_index_limit(trgPixSubBw, [imgW, imgH, nFrame]);

% Get isolated pixel indices
distMap = reshape(distMap, [imgH, imgW, 1, nFrame]);
distCur = distMap(holePix.ind);
isolatedPixelInd = distCur == 0;

% Update valid flow weight
validIndFw = validIndFw & ~isolatedPixelInd;
validIndBw = validIndBw & ~isolatedPixelInd;

% Update flow neighbors
trgPixSubFwC = trgPixSubFw(validIndFw, :);
trgPixSubBwC = trgPixSubBw(validIndBw, :);

% ========================================================================================
% 1. Distance-based weight
% ========================================================================================
interpolationKernel = 'linear';
distFw = vc_interp3(distMap, trgPixSubFwC, interpolationKernel);
distBw = vc_interp3(distMap, trgPixSubBwC, interpolationKernel);

distCurFw = distCur(validIndFw);
distCurBw = distCur(validIndBw);

distOffsetFw = vc_clamp(distCurFw - distFw, -1, 1);
distOffsetBw = vc_clamp(distCurBw - distBw, -1, 1);

fwWeight(validIndFw) = exp(distOffsetFw);
bwWeight(validIndBw) = exp(distOffsetBw);
% fwWeight(validIndFw) = opt.alphaT.^(distCur(validIndFw) - distFw);
% bwWeight(validIndBw) = opt.alphaT.^(distCur(validIndBw) - distBw);

% ========================================================================================
% 2. Confidence-based weight
% ========================================================================================
if(opt.useConfWeight)
    flowConfIndF = holePix.indFt(:,1,3);
    flowConfIndB = holePix.indFt(:,2,3);
    
    fwWeight = fwWeight.*videoFlow(flowConfIndF);
    bwWeight = bwWeight.*videoFlow(flowConfIndB);
end

% ========================================================================================
% 3. Occlusion-based weight
% ========================================================================================
if(opt.useOccWeight)
    flowVecFw = videoFlowF(flowInd(validIndFw,:));
    flowVecBw = videoFlowB(flowInd(validIndBw,:));
    
    flowVecFwBw = vc_interp3(videoFlowB, trgPixSubFwC);
    flowVecBwFw = vc_interp3(videoFlowF, trgPixSubBwC);
    
    flowVecFwSum = flowVecFw + flowVecFwBw;
    flowVecBwSum = flowVecBw + flowVecBwFw;
    
    sigmaF = 5;
    fwWeightOcc  = exp(-sum(flowVecFwSum.^2, 2)/(2*sigmaF.^2));
    bwWeightOcc  = exp(-sum(flowVecBwSum.^2, 2)/(2*sigmaF.^2));
    
    fwWeight(validIndFw) = fwWeight(validIndFw).*fwWeightOcc;
    bwWeight(validIndBw) = bwWeight(validIndBw).*bwWeightOcc;
end

end
