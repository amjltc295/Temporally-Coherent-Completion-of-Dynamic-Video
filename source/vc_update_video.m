% =========================================================================
% Video update
% =========================================================================

function [videoColor, videoFlow] = vc_update_video(videoColor, videoFlow, NNF, opt)
% VC_UPDATE_VIDEO: Given the nearest neighbor field, iteratively update the
% color and the flow
% Input:
%   - videoData:    video color       - [imgH] x [imgW] x [3] x [nFrame]
%   - videoFlow:    fw/bw flow field  - [imgH] x [imgW] x [2] x [nFrame] x [2]
%   - holeMask:     missing regions   - [imgH] x [imgW] x [nFrame]
%   - occMask:      occlusion mask    - [imgH] x [imgW] x [nFrame]
%   - NNF:          nearest neighbor field
%   - opt:          parameters
% Output:
%   - videoData: updated colors
%   - videoFlow: updated flow

% =====================================================================
% Update the videoData and videoFlow
% =====================================================================
% (1) Spatial color voting
colorData = vc_voting_color(videoColor, NNF);
videoColor(NNF.holePix.indC) = colorData;

% (2) Fix color, update flow
[flowDataF, flowDataB] = vc_update_flow(videoColor, videoFlow, NNF);
videoFlow(NNF.holePix.indFt(:,:,1)) = flowDataF;
videoFlow(NNF.holePix.indFt(:,:,2)) = flowDataB;
% Update flow confidence
videoFlow(NNF.holePix.indFt(:,:,3)) = ...
    vc_update_flow_conf(videoFlow, NNF.holePix, opt.sigmaF(opt.iLvl));

% Find flow neighbors
flowNN = vc_get_flowNN(videoFlow, NNF.holePix);

% (3) Fix flow, update color
indValid = flowNN(:,3) ~= 0;

interpolationKernel = 'bicubic';
colorDataFn = vc_interp3(videoColor, flowNN(indValid, :), interpolationKernel);
colorData   = colorData(indValid, :);

% Color update
colorDataN = update_color(colorData, colorDataFn, opt.alphaT);
videoColor(NNF.holePix.indC(indValid,:)) = colorDataN;

end
