function videoDataLab = vc_video_rgb2lab(videoData)
%
% VC_VIDEO_RGB2LAB: convert the RGB to CIELab format
%
% Input:
% - videoData: the video data of size [imgH] x [imgW] x [nCh] x [nFrame] 
%
% Output:
% - videoDataLab: video data in CIELab

fprintf('Converting video from RGB to CIELab: \n');

tic;
videoData    = im2double(videoData);
videoDataLab = zeros(size(videoData), 'single');
nFrame = size(videoData, 4);
for i = 1: nFrame
    videoDataLab(:,:,:,i)  = colorspace('rgb->lab', videoData(:,:,:,i));
end
t = toc;
fprintf('%30sdone in %.03f seconds \n', '', t);

end