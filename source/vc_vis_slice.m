function vc_vis_slice(videoName)

videoName = 'FBMS_goats01';
resPath   = fullfile('result', 'vis_slice');

% Load input video and mask
[videoColor, holeMask] = vc_load_input_data(videoName, 'avi');

% Load output
videoResPath = fullfile('result', 'completion_ours', 'results');
videoResName = [videoName, '_color_ours.avi'];
vidObj = VideoReader(fullfile(videoResPath, videoResName));
videoColorRes = read(vidObj);

% Visualize XT slices
[videoVisXT, videoVisXTb] = vis_xt(videoColorRes, holeMask);


% Export video
delayRate = 6; %
fps = 30/delayRate;
save_video(videoVisXT, fullfile(resPath,  [videoName, '_XTslice.avi']), fps);
save_video(videoVisXTb, fullfile(resPath, [videoName, '_XTsliceM.avi']), fps);

% videoResName = fullfile(resPath, [videoName, '_XTslice.avi']);
% wVidObj      = VideoWriter(videoResName, 'Uncompressed AVI');
% open(wVidObj);
% for iFrame = 1:size(videoVisXT, 4)
%     for i = 1:speedRate
%         writeVideo(wVidObj,   videoVisXT(:,:,:,iFrame));
%     end
% end
% close(wVidObj);

end

function save_video(video, videoResName, fps)

delayRate = 30/fps;

wVidObj      = VideoWriter(videoResName, 'Uncompressed AVI');
open(wVidObj);
for iFrame = 1:size(video, 4)
    for i = 1:delayRate
        writeVideo(wVidObj,   video(:,:,:,iFrame));
    end
end
close(wVidObj);


end

function [videoVisXT, videoMaskVisXT] = vis_xt(videoColor, holeMask)

% Video data
videoColor = im2single(videoColor);

[imgH, imgW, nCh, nFrame] = size(videoColor);
speed   = 6;
videoColor = videoColor(:,:,:,linspace(1, nFrame-speed+1, nFrame/speed));
nFrame = nFrame/speed;

% Hole mask
holeMask = holeMask(:,:,1:nFrame);
holeMask = reshape(holeMask, [imgH, imgW, 1, nFrame]);

% Get reference image
sPos = round(linspace(1, imgH, 62));
sPos = sPos(2:end-1);
nSlicePos = length(sPos);
refVideoVis = videoColor(:,:,:, round(nFrame/2));
refVideoVis = refVideoVis(:,:,:,ones(nSlicePos, 1));
refVideoVis(end-2:end,:,1,:)  = 1;

% Get XT slices
videoVisXT  = zeros(nFrame, imgW, nCh, nSlicePos);
videoVisXTb = zeros(nFrame, imgW, nCh, nSlicePos);
indFrame = 1;
for indSlice = sPos
    % Slice
    slice     = getSlice(videoColor, indSlice, 1);
    
    % Slice with mask
    maskSlice = getSlice(holeMask, indSlice, 1);
    borderSlice = bwperim(maskSlice);
    borderSlice = cat(3, borderSlice, borderSlice, borderSlice);
    sliceWithMask = slice;
    sliceWithMask(borderSlice) = 1;
    
    % Save results
    videoVisXT(:,:,:,indFrame)  = slice;
    videoVisXTb(:,:,:,indFrame) = sliceWithMask;
    
    refVideoVis(indSlice,:,:,indFrame) = 1;
    
    indFrame = indFrame + 1;
end
scale = 3;
videoVisXT  = imresize(videoVisXT,  [scale*nFrame, imgW],  'bilinear');
videoVisXTb = imresize(videoVisXTb, [scale*nFrame, imgW],  'bilinear');

% Create visualization
videoVisXT     = cat(1, refVideoVis, videoVisXT);
videoMaskVisXT = cat(1, refVideoVis, videoVisXTb);

end

function slice = getSlice(videoColor, pos, dim)

if(dim == 1) % Get TX slice
    slice = videoColor(pos, :, :, :);
    slice = squeeze(permute(slice, [4,2,3,1]));
elseif(dim == 2) % Get YT slice
    slice = squeeze(videoColor(:, pos, :, :));
    slice = permute(slice, [1,3,2]);
end
end