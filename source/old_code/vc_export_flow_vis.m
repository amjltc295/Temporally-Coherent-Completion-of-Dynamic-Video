function vc_export_flow_vis(videoFlow, videoResPath, videoName)

videoFlowRGB = vc_video_flow2color(videoFlow);
videoResName = fullfile(videoResPath, [videoName, '.avi']);

% if(~exist(videoResName, 'file'))
%     wVidObj = VideoWriter(videoResName, 'MPEG-4');
wVidObj = VideoWriter(videoResName);
wVidObj.FrameRate = 7.5;
open(wVidObj);
for i = 1: size(videoFlowRGB, 4)
    strImgID = num2str(i, '%03d');
    imgNameCur = [videoName, '_', strImgID, '.png'];
    
    img = videoFlowRGB(:,:,:,i);
    
    fontSize = round(size(img,2)*0.25);
    %         txtInserter = vision.TextInserter(strImgID, 'Color', [0, 0, 0], ...
    %             'Location', [10, 10], 'FontSize', fontSize);
    %         img = step(txtInserter, img);
    
    imwrite(img, fullfile(videoResPath, imgNameCur));
    writeVideo(wVidObj, img);
end
close(wVidObj);
% end

end