function videoColorBlend = vc_video_poisson_blend(videoTrg, videoSrc, holeMask)

nFrame = size(videoTrg, 4);
videoColorBlend = zeros(size(videoTrg), 'single');

warning('off','all');

for i = 1: nFrame
    holeMaskCur = holeMask(:,:,i);
    imgTrg      = videoTrg(:,:,:,i);
    imgSrc      = videoSrc(:,:,:,i);
    videoColorBlend(:,:,:,i) = sc_poisson_blend(imgTrg, imgSrc, holeMaskCur);
end

end
