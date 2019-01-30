function videoPyr = vc_create_video_pyramid(videoData, scaleImgPyr, videoType, opt)

if(isempty(videoData))
    videoPyr = [];
    return;
end

videoPyr = cell(opt.numPyrLvl,1);

% Progress display
if(strcmp(videoType, 'flow'))
    fprintf('Creating optical flow video pyramid: ');
elseif(strcmp(videoType, 'video'))
    fprintf('Creating input video pyramid: ');
elseif(strcmp(videoType, 'mask'))
    fprintf('Creating mask video pyramid: ');
else
    error('The format is not supported');
end
fprintf('\n');

tic;
% Resizing the video
videoPyr{1} = videoData;
for iLvl = 2: opt.numPyrLvl
    [imgH, imgW, n1, n2, n3] = size(videoData);
    imgHCurLvl = scaleImgPyr{iLvl}.imgSize(1);
    imgWCurLvl = scaleImgPyr{iLvl}.imgSize(2);
    
    videoDataCur = reshape(videoData, [imgH, imgW, n1*n2*n3]);
    videoCurLvl  = imResample(videoDataCur, [imgHCurLvl, imgWCurLvl]);
    videoPyr{iLvl} = reshape(videoCurLvl, [imgHCurLvl, imgWCurLvl, n1, n2, n3]);
end

% Additional processing for flow, video, and mask video
for iLvl = 1: opt.numPyrLvl
    if(strcmp(videoType, 'flow')) % optical flow
        videoPyr{iLvl}(:,:,1,:,:) = videoPyr{iLvl}(:,:,1,:,:)*scaleImgPyr{iLvl}.imgScale(2);
        videoPyr{iLvl}(:,:,2,:,:) = videoPyr{iLvl}(:,:,2,:,:)*scaleImgPyr{iLvl}.imgScale(1);
    elseif(strcmp(videoType, 'mask')) % mask
        videoPyr{iLvl} = videoPyr{iLvl} ~=0;
    end
end

t = toc;
fprintf('%30sdone in %.03f seconds \n', '', t);



end