function [videoDataPyr, videoFlowPyr, holeMaskPyr, scaleImgPyr] = ...
    vc_create_scale_pyramid(videoData, videoFlow, holeMask, opt)

% VC_CREATE_SCALE_PYRAMID: create multi-scale representation for color,
% flow, and mask
%
% Input:
%   - sizeVideo: [imgH] x [imgW]
%   - opt:       algorithm parameters
% Output:
%   - scaleImgPyr:
%       imgSize:  image size at the current scale
%       imgScale: the size ratio between the current image size and
%                 the original high-resolution image

scaleImgPyr  = vc_create_size_pyramid(size(videoData), opt);

videoDataPyr = vc_create_video_pyramid(videoData, scaleImgPyr, 'video', opt); % video
videoFlowPyr = vc_create_video_pyramid(videoFlow, scaleImgPyr, 'flow',  opt); % flow
holeMaskPyr  = vc_create_video_pyramid(holeMask,  scaleImgPyr, 'mask',  opt); % mask

end

function scaleImgPyr = vc_create_size_pyramid(sizeVideo, opt)

fprintf('Creating scale pyramid: \n');
tic;

% Image sizes
imgHeight = sizeVideo(1);
imgWidth  = sizeVideo(2);

% Compute the coarsest image scale
imgSizeMin  = min(imgHeight, imgWidth);
coarestScale = opt.coarestImgSize/imgSizeMin;

% Compute the scale in each layer in the image pyramid
if(opt.useLogScale) % use log scale
    scalePyr = 2.^linspace(0, log2(coarestScale), opt.numPyrLvl);
else % use linear scale
    scalePyr = linspace(1, coarestScale, opt.numPyrLvl);
end

% Image size in each layer
imgHPyr = round(imgHeight * scalePyr);
imgWPyr = round(imgWidth  * scalePyr);

% Initialize scale pyramid
scaleImgPyr = cell(opt.numPyrLvl, 1);

% Downsampled image sizes
for k = 1: opt.numPyrLvl
    scaleImgPyr{k}.imgSize  = [imgHPyr(k), imgWPyr(k)];
    scaleImgPyr{k}.imgScale = [imgHPyr(k)/imgHeight, imgWPyr(k)/imgWidth];
end

t = toc;
fprintf('%30sdone in %.03f seconds \n', '', t);

end

function videoPyr = vc_create_video_pyramid(videoData, scaleImgPyr, videoType, opt)

if(isempty(videoData))
    videoPyr = [];
    return;
end

videoPyr = cell(opt.numPyrLvl,1);

% Progress display
if(strcmp(videoType, 'flow'))
    fprintf('Creating optical flow video pyramid: ');
elseif(strcmp(videoType, 'video'))
    fprintf('Creating input video pyramid: ');
elseif(strcmp(videoType, 'mask'))
    fprintf('Creating mask video pyramid: ');
else
    error('The format is not supported');
end
fprintf('\n');

tic;

% Downsampling kernel N(0, 1)
h = fspecial('gaussian', 3, 0.8);

videoPyr{1} = videoData;

for iLvl = 2: opt.numPyrLvl
    imgHCurLvl = scaleImgPyr{iLvl}.imgSize(1);
    imgWCurLvl = scaleImgPyr{iLvl}.imgSize(2);
    
    % Previous layer
    [imgH, imgW, n1, n2] = size(videoPyr{iLvl-1});
    videoDataCur   = reshape(videoPyr{iLvl-1}, [imgH, imgW, n1*n2]);
    % Blur
    if(strcmp(videoType, 'video') || strcmp(videoType, 'flow'))
%         videoDataCur   = imfilter(videoDataCur, h, 'same', 'replicate', 'conv');
    end
    
    % Resampling with bilinear interpolation
    videoCurLvl = imResample(videoDataCur, [imgHCurLvl, imgWCurLvl]);

    % Resize to the current size
    videoPyr{iLvl} = reshape(videoCurLvl, [imgHCurLvl, imgWCurLvl, n1, n2]);
end

% =========================================================================
% Additional processing for flow, video, and mask video
% =========================================================================
if(strcmp(videoType, 'flow'))  % optical flow
    for iLvl = 1: opt.numPyrLvl
        videoPyr{iLvl}(:,:,[1,3],:) = videoPyr{iLvl}(:,:,[1,3],:)*scaleImgPyr{iLvl}.imgScale(2);
        videoPyr{iLvl}(:,:,[2,4],:) = videoPyr{iLvl}(:,:,[2,4],:)*scaleImgPyr{iLvl}.imgScale(1);
    end
end

if(strcmp(videoType, 'mask'))  % mask
    for iLvl = 1: opt.numPyrLvl
        videoPyr{iLvl} = videoPyr{iLvl} > 0.0;
    end
end

t = toc;
fprintf('%30sdone in %.03f seconds \n', '', t);



end


