function vc_vis_color(videoData, iter, opt, spVoteFlag)

% VC_VIS_COLOR: visualize the intermediate results for color synthesis

videoDataRGB = vc_video_lab2rgb(videoData);
% videoDataRGB = videoData;

% Specify image path
if(spVoteFlag)
    imgPath = fullfile(opt.iterSpResPath, ['level', num2str(opt.iLvl)]);
else
    imgPath = fullfile(opt.iterResPath,   ['level', num2str(opt.iLvl)]);
end

if(~exist(imgPath, 'dir'))
    mkdir(imgPath);
end

% Font size
fontSizeRatio = 0.1;
fontSize = round(size(videoDataRGB,2) * fontSizeRatio);

nFrame = size(videoDataRGB, 4);
for i = 1: nFrame
    strImgID = num2str(i, '%03d');
    
    img = videoDataRGB(:,:,:,i);
    
    % Insert text
    txtInserter = vision.TextInserter(strImgID, 'Color', [255, 255, 0], ...
        'Location', [10, 10], 'FontSize', fontSize);
    img = step(txtInserter, img);
    
    % Save result
    imgName = [opt.videoName, '_', num2str(i, '%03d'),'_iter_' num2str(iter, '%03d'), '.png'];
    imwrite(img, fullfile(imgPath, imgName));
end

end