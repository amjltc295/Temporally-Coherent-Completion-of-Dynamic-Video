function [videoDataPyr, videoDataPyrNNF] = vc_video_synthesis(videoDataPyr, videoFlowPyr, maskPyr, opt)

%%

%% Video synthesis
opt.flowFlag = 0;

% Initialize the NNF
NNF = [];
videoDataPyrNNF = cell(opt.numPyrLvl, 1);
numIterLvl = opt.numIter;
pyrLvl = opt.numPyrLvl: -1 : opt.topLevel;

% === Coarse-to-fine video completion ===
for iLvl = pyrLvl
    % The video and hole mask for the current level
    videoData = videoDataPyr{iLvl};
    videoFlow = videoFlowPyr{iLvl};
    holeMask = maskPyr{iLvl};
    
    % === Prepare video and NNF for the current level ===
    fprintf('--- Initialize NNF: \n');
    [videoData, videoFlow, NNF] = vc_init_lvl_nnf(videoData, videoFlow, holeMask, NNF, iLvl, opt);
    
    % Number of iterations at the current level
    numIterLvl = max(numIterLvl - opt.numIterDec, opt.numIterMin);
    
    fprintf('--- Pass... level: %d, #Iter: %d, #uvPixels: %7d\n', iLvl, numIterLvl, NNF.uvPix.numUvPix);
    fprintf('--- %3s\t%12s\t%12s\t%10s\n', 'iter', '#PropUpdate', '#RandUpdate', 'AvgCost');
    
    % === Run PatchMatch ===
    if(iLvl == opt.numPyrLvl)
        % At the coarsest level, run PM iteration without voting
        [videoData, NNF] = vc_pass(videoData, videoFlow, holeMask, NNF, numIterLvl, iLvl, opt, 1);
        [videoData, NNF] = vc_pass(videoData, videoFlow, holeMask, NNF, numIterLvl, iLvl, opt, 0);
    else
        [videoData, NNF] = vc_pass(videoData, videoFlow, holeMask, NNF, numIterLvl, iLvl, opt, 0);
    end
    
    % Save the result
    videoDataPyr{iLvl} = videoData;
    videoDataPyrNNF{iLvl} = NNF;
    
    % Save the results
    videoResPath = fullfile(opt.resPath, opt.videoName, 'video');
    videoName = [opt.videoName, '_lvl_', num2str(iLvl)];
    vc_export_video_completion(videoData, videoResPath, videoName);    
end

end