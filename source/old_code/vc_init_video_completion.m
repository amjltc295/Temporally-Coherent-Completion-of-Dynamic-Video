function videoData = vc_init_video_completion(videoData, holeMask)

nCh = size(videoData, 3);

fprintf('Initial video inpainting at the coarest level: ');

tic;
% Inpaint the video volumn using diffusion-based inpainting
for iCh = 1: nCh
    videoCh = squeeze(videoData(:,:,iCh,:));
    videoCh(holeMask) = nan;
    videoData(:,:,iCh, :) = inpaintn(videoCh);
end
t = toc;

fprintf('%24sdone in %.03f seconds \n', '',t);

end