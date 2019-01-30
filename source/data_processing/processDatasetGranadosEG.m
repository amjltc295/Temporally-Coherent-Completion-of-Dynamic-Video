% processDatasetGranadosECCV

datatsetPath = 'dataset\GranadosEG';
videoPath = fullfile(datatsetPath, 'video_orig');
videoResPath = fullfile(datatsetPath, 'video');
if(~exist(videoResPath, 'dir'))
    mkdir(videoResPath);
end

holePath  = fullfile(datatsetPath, 'hole_orig');
holeResPath  = fullfile(datatsetPath, 'hole');
if(~exist(holeResPath, 'dir'))
    mkdir(holeResPath);
end
 
videoDir = dir(fullfile(videoPath, '*.mp4'));

for iSeq = 1: length(videoDir)
    videoName = videoDir(iSeq).name;
    
    resVideoFileName = fullfile(videoResPath, [videoName(1:end-4), '.avi']);
    if(~exist(resVideoFileName, 'file'))
        inputVidObj = vision.VideoFileReader(fullfile(videoPath, [videoName(1:end-4), '.mp4']));
        holeVidObj  = vision.VideoFileReader(fullfile(holePath, [videoName(1:end-4), '_hole.mp4']));
        
        wInputVidObj = VideoWriter(fullfile(videoResPath, [videoName(1:end-4), '.avi']));
        wInputVidObj.Quality = 100;
        
        wHoleVidObj  = VideoWriter(fullfile(holeResPath,  [videoName(1:end-4), '_hole.avi']), 'Grayscale AVI');
        
        open(wInputVidObj);
        open(wHoleVidObj);
        i = 0;
        while ~isDone(inputVidObj)
            i = i + 1;
            % Write video
            videoFrame = step(inputVidObj);
            writeVideo(wInputVidObj, videoFrame);
            % Write hole
            holeFrame = step(holeVidObj);
            holeFrame = single(holeFrame ~= 1);
            writeVideo(wHoleVidObj, holeFrame(:,:,1)); 
            disp(['Processing video ', videoName, ' at frame ', num2str(i)]);
        end
        close(wInputVidObj);
        close(wHoleVidObj);
    end
end