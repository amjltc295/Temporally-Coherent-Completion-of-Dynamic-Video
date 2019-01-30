% processDatasetSegTrack

clear
clc

datatsetPath = 'dataset\SegTrackv2';

videoResPath = fullfile('dataset', 'SegTrack', 'video');
holeResPath = fullfile('dataset',  'SegTrack', 'hole');

%
videoPath = fullfile(datatsetPath, 'JPEGImages');
holePath = fullfile(datatsetPath, 'GroundTruth');

videoDir = dir(videoPath);
numVideo = length(videoDir);

% === Process videos ===
for iSeq = 3:numVideo
    videoName = videoDir(iSeq).name;
    
    vidResName = fullfile(videoResPath, ['SegTrack_', videoName, '.avi']);
    if(~exist(vidResName, 'file'))
        wVidObj = VideoWriter(vidResName);
        wVidObj.Quality = 100;
        open(wVidObj);
        % Sequences
        seqDir = dir(fullfile(videoPath, videoName, '*.png'));
        if(isempty(seqDir))
            seqDir = dir(fullfile(videoPath, videoName, '*.bmp'));
        end
        
        numImg = length(seqDir);
        for iImg = 1: numImg
            img = imread(fullfile(videoPath, videoName, seqDir(iImg).name));
            writeVideo(wVidObj, img);
            disp(['Processing video ', videoName, ' at frame ', num2str(iImg), '/', num2str(numImg)]);
        end
        close(wVidObj);
    end
end

% === Process hole masks ===

for iSeq = 3:numVideo
    videoName = videoDir(iSeq).name;
    
    holeVidResName = fullfile(holeResPath, ['SegTrack_', videoName, '_hole.avi']);
    if(~exist(holeVidResName, 'file'))
        wVidObj = VideoWriter(holeVidResName, 'Grayscale AVI');
        open(wVidObj);
        % Sequences
        
        seqDir = dir(fullfile(holePath, videoName, '1', '*.png'));
        if(isempty(seqDir))
            seqDir = dir(fullfile(holePath, videoName, '1', '*.bmp'));
        end
        
        numImg = length(seqDir);
        for iImg = 1: numImg
            img = imread(fullfile(holePath, videoName, '1', seqDir(iImg).name));
            img = im2bw(img);
            se = strel('disk', 11);
            imgD = imdilate(img, se);
            imgD = uint8(double(imgD)*255);
            writeVideo(wVidObj, imgD);
            disp(['Processing video ', videoName, ' at frame ', num2str(iImg), '/', num2str(numImg)]);
        end
        close(wVidObj);
    end
end

