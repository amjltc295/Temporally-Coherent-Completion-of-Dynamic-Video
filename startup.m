
% Video completion code
addpath('source');

% 2D interpolation
addpath(genpath('external/imrender'));

% Pidor's image/video toolbox
addpath(genpath('external/toolbox'));

% Diffusion-based inpainting
addpath('external/inpaintn');

% Color space conversion
addpath('external/colorspace');

% Distance transform
addpath('external/bwdistsc');

% 
addpath('external/export_fig');

% Optical flow
addpath('external/OpticalFlow');
addpath('external/OpticalFlow/mex');

debugMode = 0;

if(debugMode)
    dbstop if error;
end