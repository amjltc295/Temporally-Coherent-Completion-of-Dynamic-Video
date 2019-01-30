function videoData = vc_prep_video_data(videoData)
% VC_PREP_VIDEO_DATA
%
% Input:
%   - videoData: the RGB video of size [imgH] x [imgW] x [3] x [nFrame]
%   - useGrad:   flag for computing gradients
% Output:
%   - videoData: the Lab video of [imgH] x [imgW] x [3] x [nFrame]
%   When useGrad = 1, the videoData is of size [imgH] x [imgW] x [5] x [nFrame]
%   where the 4th and 5th channels are the gradients

% Convert RGB to CIElab space
videoData = vc_video_rgb2lab(videoData);

% videoData = im2single(videoData);

% Compute spatial gradients
% if(useGrad)
%     videoGrad = vc_compute_grad(videoData(:,:,1,:));
%     videoData = cat(3, videoData, videoGrad);
% end

end

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

function videoG = vc_compute_grad(videoL)

% VC_COMPUTE_GRAD: compute x- y- gradient of the video
% Input:
%   - videoL: the luminance channel of the video [imgH] x [imgW] x [nFrame]
%
% Output:
%   - videoG: the gradient x and y [imgH] x [imgW] x [2] x [nFrame]

fprintf('Computing gradients \n');

videoL = squeeze(videoL);
[imgH, imgW, nFrame] = size(videoL);

tic;
[videoGx, videoGy] = gradient2(videoL);

videoGx = reshape(videoGx, [imgH, imgW, 1, nFrame]);
videoGy = reshape(videoGy, [imgH, imgW, 1, nFrame]);

videoG = cat(3, videoGx, videoGy);
t = toc;

fprintf('%30sdone in %.03f seconds \n', '', t);

end