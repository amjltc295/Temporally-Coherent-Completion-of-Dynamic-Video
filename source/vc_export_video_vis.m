function vc_export_video_vis(videoData, holeMask, videoResPath, videoName, type)

% VC_EXPORT_VIDEO_VIS: Export the current flow or color video
%
% Input:
% - video: the video data of size [imgH] x [imgW] x [nCh] x [nFrame]        (color)
%                                 [imgH] x [imgW] x [2]   x [nFrame] x [2]] (flow)
% - holeMask: mask of unknown regions [imgH] x [imgW] x [nFrame]
% - videoResPath: result directory
% - videoName: result name

if(strcmp(type, 'CIELab')) % Video data
    videoRGB = vc_video_lab2rgb(videoData);
elseif(strcmp(type, 'Flow'))  % Flow data
    videoRGB = vc_video_flow2color(videoData);
elseif(strcmp(type, 'JetColor'))
    videoRGB = vc_video_scalar2jet(videoData);
elseif(strcmp(type, 'RGB'))
    videoRGB = videoData;
else
    error('The type should either be CIELab, Flow, or JetColor');
end

videoRGB = vc_clamp(videoRGB, 0, 1);
% Write the RGB video to file
vc_export_video(videoRGB, holeMask, videoResPath, videoName);

end

function vc_export_video(videoData, holeMask, videoResPath, videoName)

% VC_EXPORT_VIDEO: Export the current color video
%
% Input:
% - videoData: the video data of size [imgH] x [imgW] x [nCh] x [nFrame]
% - holeMask:  the hole of size [imgH] x [imgW] x [nFrame]
% - videoResPath: result directory
% - videoName: result name

if(~exist(videoResPath, 'dir'))
    mkdir(videoResPath);
end

% maskFlag = ~isempty(holeMask);

% Start exporting frames
for i = 1: size(videoData, 4)
    strImgID   = num2str(i, '%03d');
    
    % Current frame
    img = videoData(:,:,:,i);
        
    % Write images
    imgNameCur = [videoName, '_', strImgID, '.png'];
    imwrite(img, fullfile(videoResPath, imgNameCur));
end

end

function videoDataN = changeVideoFrameRate(videoData, frameRate)

[imgH, imgW, nCh, nFrame] = size(videoData);
R = 30/frameRate;
nFrameN = nFrame*R;

videoDataN = zeros(imgH, imgW, nCh, nFrameN, 'single');

for indFrame = 1: nFrame
    startFrame = 1+(indFrame-1)*R;
    endFrame   = indFrame*R;
    for j = startFrame : endFrame
        videoDataN(:,:,:,j) = videoData(:,:,:,indFrame);
    end
end

end
