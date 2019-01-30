% processDatasetSegTrack

clear 
clc

datatsetPath = 'dataset\Newson';

videoPath = fullfile(datatsetPath, 'video_orig');
holePath  = fullfile(datatsetPath, 'hole_orig');

videoResPath = fullfile(datatsetPath, 'video');
holeResPath  = fullfile(datatsetPath, 'hole');
if(~exist(videoResPath, 'dir'))
   mkdir(videoResPath); 
end
if(~exist(holeResPath, 'dir'))
   mkdir(holeResPath); 
end


videoDir = dir(fullfile(videoPath, '*.mp4'));


for iSeq = 1: length(videoDir)
    videoName = videoDir(iSeq).name;
    
    resVideoFileName     = fullfile(videoResPath, [videoName(1:end-4), '.avi']);
    resHoleVideoFileName = fullfile(holeResPath, [videoName(1:end-4), '_hole.avi']);

    if(~exist(resVideoFileName, 'file'))
        vidObj      = vision.VideoFileReader(fullfile(videoPath, [videoName(1:end-4), '.mp4']));
        holeVidObj  = vision.VideoFileReader(fullfile(holePath,  [videoName(1:end-4), '_hole.avi']));

        wVidObj      = VideoWriter(resVideoFileName);
        wVidObj.Quality = 100; 
        wHoleVidObj  = VideoWriter(resHoleVideoFileName, 'Grayscale AVI');
        open(wVidObj);
        open(wHoleVidObj);
        
        i = 0;
        while ~isDone(vidObj)
            i = i + 1;
            % Write video
            videoFrame = step(vidObj);
            writeVideo(wVidObj, videoFrame);
            
            % Write hole
            holeFrame = step(holeVidObj);
            holeFrame = single(holeFrame~=0);
            writeVideo(wHoleVidObj, holeFrame(:,:,1));
            
            disp(['Processing video ', videoName, ' at frame ', num2str(i)]);
        end
        close(wVidObj);
    end
end