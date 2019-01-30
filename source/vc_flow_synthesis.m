function [videoFlowPyr, videoFlowPyrNNF] = vc_flow_synthesis(videoFlowPyr, maskPyr, opt)

%%

%%
%% Flow synthesis
opt.flowFlag = true(1,1);

% Initialize the NNF
NNF = [];
videoFlowPyrNNF = cell(opt.numPyrLvl, 1);
numIterLvl = opt.numIter;
pyrLvl = opt.numPyrLvl: -1 : opt.topLevel;

% === Coarse-to-fine video completion ===
for iLvl = pyrLvl
    % The flow video and hole mask for the current level
    videoFlow = videoFlowPyr{iLvl};
    holeMask = maskPyr{iLvl};
    % Dilate the hole mask avoid inaccurate flow at the boundary
    se = strel('disk', 7);
    holeMask = imdilate(holeMask, se);
    
    % === Prepare video and NNF for the current level ===
    fprintf('--- Initialize NNF: \n');
    [videoFlow, NNF] = vc_init_lvl_nnf_flow(videoFlow, holeMask, NNF, iLvl, opt);
    
    % Number of iterations at the current level
    numIterLvl = max(numIterLvl - opt.numIterDec, opt.numIterMin);
    
    fprintf('--- Pass... level: %d, #Iter: %d, #uvPixels: %7d\n', iLvl, numIterLvl, NNF.uvPix.numUvPix);
    fprintf('--- %3s\t%12s\t%12s\t%10s\n', 'iter', '#PropUpdate', '#RandUpdate', 'AvgCost');
    
    % === Run PatchMatch ===
    if(iLvl == opt.numPyrLvl)
        % At the coarsest level, run PM iteration without voting
        [videoFlow, NNF] = vc_pass_flow(videoFlow, holeMask, NNF, numIterLvl, iLvl, opt, 1);
        [videoFlow, NNF] = vc_pass_flow(videoFlow, holeMask, NNF, numIterLvl, iLvl, opt, 0);
    else
        [videoFlow, NNF] = vc_pass_flow(videoFlow, holeMask, NNF, numIterLvl, iLvl, opt, 0);
    end
    
    % Save the result
    videoFlowPyr{iLvl} = videoFlow;
    videoFlowPyrNNF{iLvl} = NNF;
    
    % Flow visualization
    videoResPath = fullfile(opt.resPath, opt.videoName, 'flow');
    videoName    = [opt.videoName, '_flow_ours_lvl_', num2str(iLvl)];
    vc_export_flow_vis(videoFlow, videoResPath, videoName);
end

end