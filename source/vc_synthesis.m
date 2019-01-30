function [videoColor, videoFlow] = vc_synthesis(videoColorPyr, videoFlowPyr, maskPyr, opt)
% VC_SYNTHESIS:
%   Video synthesis with joint color and flow patch-based optimization
%
% Input:
%   - videoDataPyr: video color pyramid
%   - videoFlowPyr: video flow pyramid
%   - maskPyr:      video mask pyramid
% Output:
%   - videoData: synthesized video
%   - videoFlow: synthesized flow
% =========================================================================

% Initialize the neearest neighbor field
opt.numIterLvl = opt.numIter;
NNF         = [];
videoFlow   = [];

% Coarse-to-fine video completion
for iLvl = opt.numPyrLvl: -1 : opt.topLevel
    opt.iLvl     = iLvl;                               % Current level
    
    % The flow video and hole mask for the current level
    holeMask   = maskPyr{iLvl};                        % Hole
    
    % =========================================================================
    % Prepare NNF for the current level
    % =========================================================================
    fprintf('--- Initialize NNF: \n');
    % Initialize NNF
    NNF = vc_init_nnf_lvl(holeMask, videoFlowPyr{iLvl}, NNF, opt);
    opt.wPatchM = NNF.wPatchM;
    
    % Display progress
    fprintf('--- Pass... level: %d, #Iter: %d, #uvPixels: %7d\n', ...
        iLvl, opt.numIterLvl, NNF.trgPix.numPix);
    fprintf('--- %3s\t%12s\t%12s\t%12s\t%10s\n', ...
        'iter', '#Prop-Space', '#Prop-Time', '#RandUpdate', 'AvgCost');
    
    % =========================================================================
    % Prepare video and flow for the current level
    % =========================================================================
    
    if(iLvl == opt.numPyrLvl)
        % Initialize color and flow
        videoFlow    = videoFlowPyr{iLvl};
        videoColor   = videoColorPyr{iLvl};
    else
        % Upsample the flow field from the previous level
        videoFlow = vc_upsample_flow(NNF, videoFlow, videoFlowPyr{iLvl});
        
        % Find flow neighbors
        flowNN = vc_get_flowNN(videoFlow, NNF.holePix);
        
        % Upsample the colors from the previous level
        videoColor = videoColorPyr{iLvl};
        
        % Run spatial propagation on invalid source patches (e.g., boundary pixels)
        trgPatch = videoColor(NNF.trgPatchInd);
        for i = 1:4
            [NNF, ~] = vc_propagate_spatial(trgPatch, videoColor, NNF, opt, i);
        end
        
        % Minimizing color spatial cost
        colorData  = vc_voting_color(videoColor, NNF);
        videoColor(NNF.holePix.indC) = colorData;

        % Minimizing color spatial cost + NNF update
        [videoColor, NNF] = vc_pass(videoColor, videoFlow, flowNN, NNF, opt, lockFlag);
    end
    
    % =========================================================================
    % Run patch-based synthesis
    % =========================================================================
    if(iLvl == opt.numPyrLvl)
        % At the coarsest level, run PM iteration without voting
        lockFlag = 1;
        [videoColor, NNF] = vc_pass(videoColor, [], [], NNF, opt, lockFlag);
        lockFlag = 0;
        [videoColor, NNF] = vc_pass(videoColor, [], [], NNF, opt, lockFlag);
        
        % Extend the nearest neighbor field to boundaries
        NNF.srcPos.map(:,:,[1:2, end-1:end],:) = NNF.srcPos.map(:,:,[3,3, end-2, end-2], :);
        NNF.srcPos.map(:,:, 1, 3)     = NNF.srcPos.map(:,:, 1, 3) - 2;
        NNF.srcPos.map(:,:, 2, 3)     = NNF.srcPos.map(:,:, 2, 3) - 1;
        NNF.srcPos.map(:,:, end-1, 3) = NNF.srcPos.map(:,:, end-1, 3) + 1;
        NNF.srcPos.map(:,:, end, 3)   = NNF.srcPos.map(:,:, end, 3)   + 2;
        NNF.srcTfmG.map(:,:,[1:2, end-1:end],:) = NNF.srcTfmG.map(:,:,[3, 3, end-2, end-2],:);
    else
        % Alternating optimization between color and flow
        % (1) Flow update
        [flowDataF, flowDataB] = ...                          % Refine flow
            vc_update_flow(videoColor, videoFlow, NNF.holePixF, NNF.holePixN);
        videoFlow(NNF.holePix.indFt(:,:,1)) = flowDataF;      % Update forward flow
        videoFlow(NNF.holePix.indFt(:,:,2)) = flowDataB;      % Update backward flow
        flowDataConf = vc_update_flow_conf(videoFlow, NNF.holePix, opt.sigmaF(opt.iLvl));
        videoFlow(NNF.holePix.indFt(:,:,3)) = flowDataConf;   % Update flow confidence

        flowNN = vc_get_flowNN(videoFlow, NNF.holePix);       % Find flow neighbors
        
        % (2) Color update
        % Minimizing color spatial cost + NNF update
        [videoColor, NNF] = vc_pass(videoColor, videoFlow, flowNN, NNF, opt, lockFlag);
    end
    
    % Number of iterations at the current level
    opt.numIterLvl = max(opt.numIterLvl - opt.numIterDec, opt.numIterMin);
    
    % =========================================================================
    % Exporting the results at the current level
    % =========================================================================
    if(opt.visResFlag)
        if(iLvl~=opt.topLevel)
            continue;
        end
        % Color visualization
        %         videoColorName    = [opt.videoName, '_color_ours_lvl_', num2str(iLvl)];
        %         vc_export_video_vis(videoColor, [], opt.colorResPath, videoColorName, 'CIELab');
        
        % Flow visualization
        %         videoFlowName    = [opt.videoName, '_flow_ours_lvl_', num2str(iLvl)];
        %         vc_export_video_vis(videoFlow,  [], opt.flowResPath,  videoFlowName, 'Flow');
        
        % DistMap visualization
        %         distMapVis  = vc_get_flowDistMap(videoFlow, NNF.holePix);
        %         videoDistMapName = ['dist_iLvl_', num2str(iLvl)];
        %         vc_export_video_vis(distMapVis, [], opt.visDistResPath, videoDistMapName, 'JetColor');
        
        % Visualizing the NNF at each iteration
        vc_vis_nnf(NNF, 1, opt);
        
        % Flow confidence visualization
        %         vc_export_video_vis(squeeze(videoFlow(:,:,5,:)), [], opt.visFlowConfResPath, ...
        %             ['errFwBw_lvl_', num2str(iLvl)], 'JetColor');
        %         vc_export_video_vis(squeeze(videoFlow(:,:,6,:)), [], opt.visFlowConfResPath, ...
        %             ['errBwFw_lvl_', num2str(iLvl)], 'JetColor');
    end
    
end

% Reconstruction
reconType = 3;
if(reconType == 1)
    % Pixel-based reconstruction (Integer positions)
    NNF.srcPos.data = round(NNF.srcPos.data);
    videoTemp = zeros(size(videoColor), 'single');
    videoTemp(NNF.trgPix.indC)   = vc_interp3(videoColor, NNF.srcPos.data);
    videoColor(NNF.holePix.indC) = videoTemp(NNF.holePix.indC);
elseif(reconType == 2)
    % Pixel-based reconstruction (sub-pixels positions)
    videoTemp = zeros(size(videoColor), 'single');
    videoTemp(NNF.trgPix.indC)   = vc_interp3(videoColor, NNF.srcPos.data);
    videoColor(NNF.holePix.indC) = videoTemp(NNF.holePix.indC);
elseif(reconType == 3)
    % Patch-based reconstruction
    videoColor(NNF.holePix.indC) = vc_voting_color(videoColor, NNF);
else
    
end

end

