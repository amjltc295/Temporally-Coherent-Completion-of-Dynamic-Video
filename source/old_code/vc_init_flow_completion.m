function videoFlow = vc_init_flow_completion(videoFlow, holeMask)
%%

%%
[imgH, imgW, nCh, nFrame, nFlow] = size(videoFlow);

fprintf('Initial flow inpainting at the coarest level: ');

% Dilate the hole mask to avoid inaccurate flow at object boundaries
se = strel('disk', 7);
holeMask = imdilate(holeMask, se);

tic;
% Inpaint the video volumn using diffusion-based inpainting 
for iFlow = 1:nFlow
    for iCh = 1: nCh
        videoCh = squeeze(videoFlow(:,:,iCh,:, iFlow));
        videoCh(holeMask) = nan;
        videoFlow(:,:,iCh,:, iFlow) = inpaintn(videoCh);
    end
end
t = toc;

fprintf('done in %.03f seconds \n', t);

end