function videoDataLab = vc_video_rgb2luv(videoData)
%%

%%
fprintf('Converting video from RGB to CIELab: ');

% Convert the RGB to CIELab format
videoDataLab = zeros(size(videoData), 'single');
nFrame = size(videoData, 4);
tic;
% C = makecform('srgb2lab');
for i = 1: nFrame
%     videoDataLuv(:,:,:,i) = rgbConvert(videoData(:,:,:,i), 'luv', true);
    videoDataLab(:,:,:,i) = rgb2lab(videoData(:,:,:,i));
end
t = toc;
fprintf('done in %.03f seconds \n', t);


end