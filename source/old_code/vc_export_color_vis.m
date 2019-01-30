function vc_export_color_vis(videoData, videoResPath, videoName)

% VC_EXPORT_COLOR_VIS: Export the current color video
%
% Input:
% - videoData: the video data of size [imgH] x [imgW] x [nCh] x [nFrame] 
%

if(~exist(videoResPath, 'dir'))
    mkdir(videoResPath);
end

videoDataRGB = vc_video_lab2rgb(videoData);
videoResName = fullfile(videoResPath, [videoName, '.avi']);

wVidObj = VideoWriter(videoResName);
wVidObj.FrameRate = 7.5;

% Start exporting frames
open(wVidObj);
for i = 1: size(videoDataRGB, 4)
    strImgID = num2str(i, '%03d');
    imgNameCur = [videoName, '_', strImgID, '.png'];
    
    img = videoDataRGB(:,:,:,i);
    
    imwrite(img, fullfile(videoResPath, imgNameCur));
    writeVideo(wVidObj, img);
end
close(wVidObj);

end