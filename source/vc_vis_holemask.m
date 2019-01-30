function vc_vis_holemask(videoName)

% datasetName = 'all';
% videoName = 'GranadosEG_duo.avi';

resVisPath = 'hole_overlay';
if(~exist(resVisPath, 'dir'))
    mkdir(resVisPath);
end

% Process visualization
videoResName = fullfile('dataset', resVisPath, [videoName(1:end-4), '_maskoverlay.mp4']);

holeExt = 'avi';
if(exist(videoResName, 'file'))
    return;
end
disp(['Process video ', videoName]);

inputVidObj = VideoReader(fullfile('dataset',  'video', videoName));
holeFileName = fullfile('dataset', 'hole',  [videoName(1:end-4), '_hole.avi']);
if(exist(holeFileName, 'file'))
    holeVidObj  = VideoReader(holeFileName);
else
    holeMask = imread([holeFileName(1:end-4), '.png']);
    holeExt = 'png';
end
wVidObj = VideoWriter(videoResName, 'MPEG-4');
wVidObj.Quality = 100;
open(wVidObj);
se = strel('disk', 3);
for i = 1: inputVidObj.NumberOfFrames
    img  = read(inputVidObj, i);
    if(strcmp(holeExt, 'avi'))
        hole = read(holeVidObj, i);
        hole = hole(:,:,1);
        hole = hole == 255;
    else
        hole = holeMask;
    end
    
    holeEgde = imdilate(edge(hole), se);
    
    imgR = img(:,:,1);
    imgG = img(:,:,2);
    imgB = img(:,:,3);
    
    imgR(holeEgde) = 255;
    imgG(holeEgde) = 0;
    imgB(holeEgde) = 0;
    
    imgVis = cat(3, imgR, imgG, imgB);
    writeVideo(wVidObj, imgVis);
    disp(['Process video ', videoName, ' at frame ', num2str(i), '/', num2str(inputVidObj.NumberOfFrames)]);
end

close(wVidObj);


end