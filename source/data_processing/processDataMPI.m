%

function processDataMPI

dataResPath  = 'dataset/video';
flowResPath  = 'dataset/flow_vis';
if(~exist(flowResPath))
    mkdir(flowResPath);
end
    
flowDataPath = 'flow/MPI-Sintel-complete/training/final';
flowVisPath  = 'flow/MPI-Sintel-complete/training/flow_viz';

flowDataDir = dir(flowDataPath);
flowDataDir(1:2) = [];


numSeq = length(flowDataDir);

for i = 1: numSeq
    seqName = flowDataDir(i).name;
    
    % Convert image sequence to video
    convertVideo(flowDataPath, seqName, fullfile(dataResPath, ['MPI_', seqName, '.avi']));
    
    % Convert flow visualization sequence to video
    convertVideo(flowVisPath, seqName,  fullfile(flowResPath, ['MPI_', seqName, '_flow_vis.avi']));

    disp(['Process video ', seqName]);
end

end

function convertVideo(flowDataPath, seqName, videoResName)

seqDir = dir(fullfile(flowDataPath, seqName, '*.png'));
numImg = length(seqDir); 
writerObj = VideoWriter(videoResName, 'Uncompressed AVI');
open(writerObj);

for i = 1:numImg
    img = imread(fullfile(flowDataPath, seqName, seqDir(i).name));
    
    writeVideo(writerObj, img);
%     figure(1); imshow(img);
end
close(writerObj);

end