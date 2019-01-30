flowCodePathMatlab = 'flow\MPI-Sintel-complete\flow_code\MATLAB';
flowPath     = 'flow\MPI-Sintel-complete\training\flow';

addpath(flowCodePathMatlab);
addpath(flowPath);

flowDir = dir(flowPath);
flowDir(1:2) = [];

numSeq = length(flowDir);

for i = 1: numSeq
    seqName = flowDir(i).name;
    flowDataName = fullfile(flowPath, [seqName, '_flow.mat']);
    
    if(~exist(flowDataName, 'file'))
        flowDataDir = dir(fullfile(flowPath, seqName, '*.flo'));
        
        % Get spec
        flowImg = fullfile(flowPath, seqName, flowDataDir(1).name);
        flowImg = readFlowFile(flowImg);
        [imgH, imgW, nCh] = size(flowImg);
        numFlowImg = length(flowDataDir);
        
        % Initialize flow data
        videoFlowF = zeros(imgH, imgW, 2, numFlowImg + 1, 'single');   % Forward flow field
        videoFlowB = zeros(imgH, imgW, 2, numFlowImg + 1, 'single');   % Dummy
        for ii = 1: numFlowImg
            flowImg = fullfile(flowPath, seqName, flowDataDir(ii).name);
            videoFlowF(:,:,:,ii) = readFlowFile(flowImg);
        end
        
        flowDataName = fullfile(flowPath, [seqName, '_flow.mat']);
        save(flowDataName, 'videoFlowF', 'videoFlowB');       
    end
    disp(['Processing dataset ', num2str(i), '/', num2str(numSeq)]);
end