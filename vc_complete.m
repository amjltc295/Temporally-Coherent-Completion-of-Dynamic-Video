function vc_complete(videoName)
%VC_COMPLETE: Main function for video completion
%
% Input:
%   - videoName: the video filename (without extension)
%
% Contact:
% Jia-Bin Huang
% Electrical and Computer Enginnering
% Virginia Tech
% www.jiabinhuang.com

startup;
clc;
close all;

% dbstop if error

% Temporary inputs
% videoName = '003234408d';
% videoName = 'davis_bmx-trees';

videoExt  = 'mp4';
% videoExt  = 'avi';

fprintf('Process video %s \n', videoName);

% =========================================================================
% Initialize algorithm parameters
% =========================================================================
opt = vc_init_opt(videoName);

% =========================================================================
% Load video, hole and flow data
% =========================================================================
% Start and end frame
frameInd.start = 1;
frameInd.end   = 15;

% Load input video and holeMask
[videoColor, holeMask, loadFlag] = vc_load_input_data(videoName, videoExt, frameInd);

video_len = size(videoColor)
mask_len = size(holeMask)
len = min(video_len(4), mask_len(3))
videoColor = videoColor(:, :, :, 1:len);
holeMask = holeMask(:, :, 1:len);

holeMask = 1 - holeMask;

videoColor = im2single(videoColor);

% Load/compute forward and backward optical flow
videoFlow  = vc_compute_flow(videoColor, opt.flowDataPath, frameInd);

% videoFlow = test_flow_est(videoColor, videoFlow, holeMask, opt);

% Selecting only partial frames (for developing the algorithm)
[videoColor, holeMask, videoFlow] = ...
    selParialFrames(videoColor, holeMask, videoFlow, frameInd);

% Convert RGB to Lab colors
% videoColor = vc_prep_video_data(videoColor);
% videoColor = im2single(videoColor);

% =========================================================================
% Initial completion of color and flow
% =========================================================================
% Dilate the original mask by one pixel
holeMaskD     = imdilate(holeMask, strel('disk', 1));

% TEMP
if(strcmp(videoName, 'GranadosEG_duo'))
    holeMaskD = imdilate(holeMask, strel('disk', 11));
end

% === Color initialization ===
videoColorSyn = vc_init_completion(videoColor, holeMaskD, 2);

% === Flow initialization ===
% videoFlowSyn = vc_init_completion(videoFlow, holeMaskD, 2);
videoFlowSyn = vc_init_completion_flow(videoFlow, holeMaskD);

% =========================================================================
% Create video pyramid
% =========================================================================
[videoColorPyr, videoFlowPyr, maskPyr, scaleImgPyr] = ...
    vc_create_scale_pyramid(videoColorSyn, videoFlowSyn, holeMaskD, opt);

% Prepare the parameter for flow confidence estimation
opt.sigmaF = ones(opt.numPyrLvl, 1);
for i = 1:opt.numPyrLvl
    opt.sigmaF(i) = opt.sigmaF(i)*scaleImgPyr{i}.imgScale(1);
end

% =========================================================================
% Video completion as a patch-based synthesis framework
% =========================================================================
[videoColorSyn, videoFlowSyn] = vc_synthesis(videoColorPyr, videoFlowPyr, maskPyr, opt);

% Poisson blending
if(opt.usePoissonBlend)
    videoColorSyn = vc_poisson_blend(videoColor, videoColorSyn, holeMask, 3);
end

% =========================================================================
% Export final results (color and flow completion)
% =========================================================================
warning off

% Export final color and flow
videoColorName = [opt.videoName, '_color_ours'];
% vc_export_video_vis(videoColorSyn, holeMask, opt.colorResPath, videoColorName, 'CIELab');
vc_export_video_vis(videoColorSyn, holeMask, opt.colorResPath, videoColorName, 'RGB');

videoFlowName  = [opt.videoName, '_flow_ours'];
vc_export_video_vis(videoFlowSyn,  holeMask, opt.flowResPath, videoFlowName, 'Flow');

% Create a copy at the results folder
resFinalPath = fullfile(opt.resPath, 'results');
if(~exist(resFinalPath, 'dir'))
    mkdir(resFinalPath);
end
% copyfile(fullfile(opt.colorResPath, [videoColorName, '.avi']), ... % Color
%     fullfile(resFinalPath, [opt.videoName, '_color_ours.avi']));
% copyfile(fullfile(opt.flowResPath, [videoFlowName, '.avi']), ...   % Flow
%     fullfile(resFinalPath, [opt.videoName, '_flow_ours.avi']));

end

function [videoColor, holeMask, videoFlow] = ...
    selParialFrames(videoColor, holeMask, videoFlow, frameInd)

% startFrame = frameInd.start;
% endFrame   = frameInd.end;

imgH = size(videoColor, 1);
imgW = size(videoColor, 2);

rRange = round(1:imgH);
cRange = round(1:imgW);

% Select only a few frames
videoColor = videoColor(rRange,cRange,:,:);

% Hole mask original
% fprintf('W: %i\n', imgW);
% fprintf('H: %i\n', imgH);
holeMask  = holeMask(rRange,cRange, :);

% Selecting a few frames
videoFlow = videoFlow(rRange,cRange, :, :);

end
