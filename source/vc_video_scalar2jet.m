function videoRGB = vc_video_scalar2jet(videoData)

[imgH, imgW, nFrame] = size(videoData);

nCh = 3; % Color channels

videoData = videoData/max(videoData(:)); % Normalize to 1
cmap     = jet(256);

% Initialization
videoRGB = zeros(imgH, imgW, nCh, nFrame, 'single');
for i = 1: nFrame
    videoRGB(:,:,:,i) = ind2rgb(gray2ind(videoData(:,:,i), 256), cmap);
end

end