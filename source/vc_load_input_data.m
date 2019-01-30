function [videoData, holeMask, loadFlag] = vc_load_input_data(videoName, videoExt, frameInd)

% VC_LOAD_INPUT_DATA
%
% Input:
%   - videoName: input video name
%   - videoExt:  exntension file, e.g., 'avi'
% Output:
%   - videoData: color video data   [imgH] x [imgW] x [3] x [nFrame]
%   - holeMask:  unknown pixel mask [imgH] x [imgW] x [nFrame]

% Specify path
videoPath = fullfile('dataset', 'video');
holePath  = fullfile('dataset', 'hole');

% =========================================================================
% Loading input video
% =========================================================================
fprintf('Loading input video: \n');
tic;
videoData = readInputVideo(videoPath, [videoName, '.', videoExt], frameInd);
t = toc;
fprintf('%30sdone in %.03f seconds \n', '', t);

% =========================================================================
% Reading hole mask
% =========================================================================
fprintf('Loading input mask: \n');
tic;
videoSize = [size(videoData, 1), size(videoData,2), size(videoData,4)];
[holeMask, loadFlag] = readHoleMaskVideo(holePath, videoName, ...
    videoSize, frameInd);
t = toc;
fprintf('%30sdone in %.03f seconds \n', '', t);

end

function videoData = readInputVideo(videoPath, videoFileName, frameInd)

% Reading input video
vidObj = VideoReader(fullfile(videoPath, videoFileName));

nFrame = round(vidObj.Duration*vidObj.FrameRate);

startFrame = frameInd.start;
endFrame   = min(frameInd.end, nFrame);

videoData = read(vidObj, [startFrame, endFrame]);

end

function [holeMask, loadFlag] = readHoleMaskVideo(holePath, videoName, videoSize, frameInd)

loadFlag = 1;

% Get the start/end frame
startFrame = frameInd.start;
endFrame   = startFrame + videoSize(3) - 1;

% File name of the hole mask
holeFileNameVideo = [videoName, '_hole.mp4'];
% holeFileNameVideo = [videoName, '_hole.avi'];
holeFileNameImg   = [videoName, '_hole.png'];

if(exist(fullfile(holePath, holeFileNameVideo), 'file'))
    % holeMask provided by a video
    vidObj = VideoReader(fullfile(holePath, holeFileNameVideo));
    holeMask = read(vidObj, [startFrame, Inf]);
    % holeMask = read(vidObj, [startFrame, endFrame]);
    if(ndims(holeMask)==4) % Remove the color channel
        holeMask = squeeze(holeMask(:,:,1,:));
    end
elseif(exist(fullfile(holePath, holeFileNameImg), 'file'))
    % holeMask provided by an image
    holeImg  = imread(fullfile(holePath, holeFileNameImg));
    holeMask = holeImg(:,:,ones(videoSize(3), 1));
elseif(strcmp(videoName(1:3), 'MPI'))
    holeFileNameImg   = 'MPI_hole.png';
    holeImg  = imread(fullfile(holePath, holeFileNameImg));
    
    holeMask  = holeImg(:,:,ones(videoSize(3), 1));
else
%     holeMask = synthetic_mask(videoSize);
    holeMask(:) = 0;
    loadFlag = 0;
end

holeMask = im2single(holeMask);

end

function holeMask = synthetic_mask(videoSize)

% Create a synthetic mask
imgH = videoSize(1);
imgW = videoSize(2);
nFrame = videoSize(3);

holeMask = zeros(imgH, imgW);

k = 4;
xVec = round(linspace(1, imgW, k+2));
yVec = round(linspace(1, imgH, k+2));

% [X, Y] = meshgrid(xVec(2:end-1), yVec(2:end-1));
[X, Y] = meshgrid(xVec([5]), yVec([3]));

p = cat(2, X(:), Y(:));

pInd = sub2ind([imgH, imgW], p(:,2), p(:,1));
holeMask(pInd) = 1;

% Apply dilation
ratio = 16;
W = round(min(imgW, imgH)/ratio);
se = strel('diamond', W);

holeMask = imdilate(holeMask, se);
holeMask = holeMask(:,:,ones(1, nFrame));

end
