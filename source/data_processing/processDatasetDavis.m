
% processDatasetDavis
vidSize = '480p';
datasetName = 'davis';
datasetPath = fullfile('dataset', datasetName, 'davis');

videoFlag     = 1;
holeMaskFlag  = 1;

imgPath  = fullfile(datasetPath, 'JPEGImages',  vidSize);
holePath = fullfile(datasetPath, 'Annotations', vidSize);
resPath  = fullfile(datasetPath, 'videos');
if(~exist(resPath, 'dir'))
    mkdir(resPath);
end

seqDir   = dir(imgPath);
se = strel('square', 15);

for iSeq = 3:length(seqDir)
    seqName = seqDir(iSeq).name;
    
    % Sequence image directory
    imgSeqDir = dir(fullfile(imgPath, seqName, ['*.jpg']));
    numImg    = length(imgSeqDir);
    
    % Hole image directory
    imgHoleDir = dir(fullfile(holePath, seqName, ['*.png']));
    
    % Initialize video objects
    videoName = [datasetName,'_', seqName,'.avi'];
    videoMp4Name = [datasetName,'_', seqName,'.mp4'];
    videoHoleName = [datasetName,'_', seqName,'_hole.avi'];
    
    disp(['Exporting video ', seqName]);
    
    if(exist(fullfile(resPath, videoHoleName), 'file'))
        continue;
    end
    
    % === Creating video objects ===
    if(videoFlag)
        wSeqVidObj   = VideoWriter(fullfile(resPath, videoName));
        wSeqVidObj.Quality = 100;
        open(wSeqVidObj);
    end
    
    if(holeMaskFlag)
        wHoleVidObj  = VideoWriter(fullfile(resPath, videoHoleName), ...
            'Grayscale AVI');
        open(wHoleVidObj);
    end
    
    % Shadow file path
    shadowPath = fullfile('dataset', 'hole_shadow', ['davis_', seqName]);
    if(exist(shadowPath,'dir'));
        shadowMaskImgDir = dir(fullfile(shadowPath, '*.png'));
        shadowMaskFlag   = 1;
    else
        shadowMaskFlag   = 0;
    end
    
    for i = 1:numImg
        % image and hole mask
        if(videoFlag)
            img     = imread(fullfile(imgPath, seqName, imgSeqDir(i).name));
            writeVideo(wSeqVidObj, img);
        end
        
        if(holeMaskFlag)
            % Object mask
            imgHole = imread(fullfile(holePath, seqName, imgHoleDir(i).name));
            imgHole = imgHole ~= 0;
            imgHole = imfill(imgHole, 'hole');
            imgHole = imdilate(imgHole, se);
            
            % Shadow mask
            if(shadowMaskFlag)
                imgSdMask = imread(fullfile(shadowPath, shadowMaskImgDir(i).name));
                imgSdMask = imgSdMask(:,:,1);
                imgSdMask = imgSdMask ~=0;
                imgSdMask = imdilate(imgSdMask, se);
                imgHole   = imgHole | imgSdMask;      % Merge with object mask
            end
            imgHole = uint8(imgHole*255);
            writeVideo(wHoleVidObj, imgHole);
        end
        
        % Input + mask
        
    end
    
    if(videoFlag)
        close(wSeqVidObj);
    end
    if(holeMaskFlag)
        close(wHoleVidObj);
    end
end
