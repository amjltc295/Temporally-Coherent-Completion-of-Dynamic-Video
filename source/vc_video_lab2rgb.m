function videoDataRGB = vc_video_lab2rgb(videoData)

% VC_VIDEO_LAB2RGB: convert the CIELAB to RGB format
%
% Input:
% - videoData: the video data of size [imgH] x [imgW] x [nCh] x [nFrame] 
%
% Output:
% - videoDataRGB: video data in RGB

% fprintf('Converting video from CIELab to RGB: \n');

% Convert the RGB to CIELab format
[imgH, imgW, nCh, nFrame] = size(videoData);
videoDataRGB = zeros(imgH, imgW, 3, nFrame, 'single');
nFrame = size(videoData, 4);
tic;
videoData = double(videoData);
for i = 1: nFrame
    videoDataRGB(:,:,:,i) = colorspace('lab->rgb', videoData(:,:,1:3,i));
end
videoDataRGB = vc_clamp(videoDataRGB, 0, 1);
t = toc;

% fprintf('%30sdone in %.03f seconds \n', '', t);

end