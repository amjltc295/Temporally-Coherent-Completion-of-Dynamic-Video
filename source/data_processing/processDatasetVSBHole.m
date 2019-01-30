% processDatasetSegTrack

clear 
clc

datatsetPath = 'dataset';

holePath  = fullfile(datatsetPath, 'hole_temp');

holeResPath  = fullfile(datatsetPath, 'hole');
if(~exist(holeResPath, 'dir'))
   mkdir(holeResPath); 
end


videoDir = dir(fullfile(holePath, '*.avi'));

for iSeq = 1: length(videoDir)
    videoName = videoDir(iSeq).name;
    
    resHoleVideoFileName = fullfile(holeResPath, [videoName(1:end-4), '_hole.avi']);

    if(~exist(resHoleVideoFileName, 'file'))
        holeVidObj  = vision.VideoFileReader(fullfile(holePath,  [videoName(1:end-4), '.avi']));

        wHoleVidObj  = VideoWriter(resHoleVideoFileName, 'Grayscale AVI');
        open(wHoleVidObj);
        
        se = strel('disk', 11);
        i = 0;
        while ~isDone(holeVidObj)
            i = i + 1;            
            % Write hole
            holeFrame = step(holeVidObj);
            holeFrame = single(holeFrame(:,:,1)~=0);
            holeFrame = imdilate(holeFrame, se);
            writeVideo(wHoleVidObj, holeFrame(:,:,1));
            
            disp(['Processing video ', videoName, ' at frame ', num2str(i)]);
        end
        close(wHoleVidObj);
        release(holeVidObj);
    end
end