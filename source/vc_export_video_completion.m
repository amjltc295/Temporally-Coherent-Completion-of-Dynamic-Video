function vc_export_video_completion(videoData, videoResPath, videoName)


if(~exist(videoResPath, 'dir'))
    mkdir(videoResPath);
end

videoDataRGB = vc_video_lab2rgb(videoData);

videoResName = fullfile(videoResPath,[videoName, '_ours.avi']);
wVidObj = VideoWriter(videoResName);
open(wVidObj);
for i = 1: size(videoDataRGB, 4)
    imgName = [videoName, '_',num2str(i, '%03d'),'.png'];
    img = videoDataRGB(:,:,:,i);
    imwrite(img, fullfile(videoResPath, imgName));
    writeVideo(wVidObj, img);
end
close(wVidObj)


end