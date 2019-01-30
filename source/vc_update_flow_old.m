function videoFlow = vc_update_flow(videoFlow, NNF, opt)


[imgH, imgW, nCh, nFrame, nFlow] = size(videoFlow);

% =========================================================================
% Enforcing flow consistency
% =========================================================================
flowErrFw_sInit = zeros(imgH, imgW, nFrame, 'single'); 
flowErrBw_sInit = zeros(imgH, imgW, nFrame, 'single'); 
flowErrFw_s  = zeros(imgH, imgW, nFrame, 'single'); 
flowErrBw_s  = zeros(imgH, imgW, nFrame, 'single'); 

% Get data term
flowDataT_orig = videoFlow(NNF.holePix.indF);
flowDataT      = flowDataT_orig;

% Initial flow visualization 
flowFwOrigVis = flowToColor(videoFlow(:,:,:,1,1));
flowBwOrigVis = flowToColor(videoFlow(:,:,:,2,2));

numIter = 6;
for iter = 1: numIter
        
    % Get flow weight for backward temporal diffusion
    [fwWeight, trgPixSubFw] = get_flow_weight(videoFlow, NNF.holePix, NNF.distMap, 'forward',  opt);
    [bwWeight, trgPixSubBw] = get_flow_weight(videoFlow, NNF.holePix, NNF.distMap, 'backward', opt);
    % Get flow weight for forward temporal neighbor
    combWeightFw = 1 + fwWeight;
    combWeightBw = 1 + bwWeight;

    % ====================================================================================
    % Update forward flow (with fixed backward flow)
    % ====================================================================================
    % Enforce forward-backward constraints
    flowDataBw = vc_interp3(videoFlow(:,:,:,:,2), trgPixSubFw);
    fwErrData  = (flowDataT(:,:,1) + flowDataBw); % error temp
    
    flowDataBw    = bsxfun(@times, fwWeight, flowDataBw);
    flowDataFwCur = flowDataT(:,:,1) - flowDataBw;
    flowDataFwCur = bsxfun(@rdivide, flowDataFwCur, combWeightFw);

    % Update forward flow
    videoFlow(NNF.holePix.indF(:,:,1)) = flowDataFwCur;
    
    % ====================================================================================
    % Update backward flow (with fixed forward flow)
    % ====================================================================================
    % Enforce backward-forward constraints 
    flowDataFw = vc_interp3(videoFlow(:,:,:,:,1), trgPixSubBw);
    bwErrData  = (flowDataT(:,:,2) + flowDataFw);   % error temp
    
    flowDataFw    = bsxfun(@times, bwWeight, flowDataFw);
    flowDataBwCur = flowDataT(:,:,2) - flowDataFw;
    flowDataBwCur = bsxfun(@rdivide, flowDataBwCur, combWeightBw);
    
    % Update forward flow
    videoFlow(NNF.holePix.indF(:,:,2)) = flowDataBwCur;
    
    % Discard the inpainted flow?
    flowDataT = cat(3, flowDataFwCur, flowDataBwCur);
    
    % =========================================================================
    % Visualize errors (optional)
    % =========================================================================
    fwErrData = sum(abs(fwErrData), 2);
    bwErrData = sum(abs(bwErrData), 2);
    if(iter == 1) % Before 
        flowErrFw_sInit(NNF.holePix.ind) = fwErrData.*(fwWeight~=0);
        flowErrBw_sInit(NNF.holePix.ind) = bwErrData.*(bwWeight~=0);
    else          % After iteration
        % Consistency term
        flowErrFw_s(NNF.holePix.ind)  = fwErrData.*(fwWeight~=0);
        flowErrBw_s(NNF.holePix.ind)  = bwErrData.*(bwWeight~=0);
        
        flowFwAfterVis = flowToColor(videoFlow(:,:,:,1,1));
        flowBwAfterVis = flowToColor(videoFlow(:,:,:,2,2));

        % Visualize error: 
        h = figure(2);
        flowEr = flowErrFw_sInit(:,:,1);
        maxFlow = max(flowEr(:));
        ha = tight_subplot(2,3,[.01 .03],[.1 .1],[.01 .01]);
        axes(ha(1)); imagesc(flowErrFw_sInit(:,:,1), [0, maxFlow]); 
        colorbar; axis image; axis off;
        title('Init cost', 'FontSize', 16);
        axes(ha(2)); imshow(flowFwOrigVis);
        title('Forward Flow (Before)', 'FontSize', 16);
        axes(ha(3)); imshow(flowBwOrigVis); 
        title('Backward Flow (Before)', 'FontSize', 16);
        
        axes(ha(4)); imagesc(flowErrFw_s(:,:,1), [0, maxFlow]);     
        colorbar; axis image; axis off;
        title('Smoothness cost', 'FontSize', 16);
        axes(ha(5)); imshow(flowFwAfterVis);
        title('Forward Flow (After)', 'FontSize', 16);
        axes(ha(6)); imshow(flowBwAfterVis);
        title('Backward Flow (After)', 'FontSize', 16);

        print(h, '-dpng', fullfile(opt.visFlowResPath, [opt.videoName, '_flowErrFw_iter_', num2str(iter-1),'.png']));
    end
end 

end


function [flowWeight, trgPixNSub] = get_flow_weight(videoFlow, holePix, distMap, ...
    directFlag,  opt)

% ========================================================================================
% Setting up forward or backward flow weight parameters
% ========================================================================================
if(strcmp(directFlag, 'forward') && opt.useFwFlow)
    frameInc = 1;
    videoFlow = videoFlow(:,:,:,:,1);
    bdLabel = 2;
elseif(strcmp(directFlag, 'backward') && opt.useBwFlow)
    frameInc = -1;
    videoFlow = videoFlow(:,:,:,:,2);
    bdLabel = 1;
else
    flowWeight = [];
    trgPixNSub = [];
    return;
end

[imgH, imgW, nCh, nFrame] = size(videoFlow);

% ========================================================================================
% Initialize flow weight and flow neighbor positions
% ========================================================================================
% Get flow weights
flowWeight = zeros(holePix.numPix, 1, 'single');

% Get flow vectors
flowVec  = videoFlow(holePix.indF(:,:,1));
% Add flow vectors from the forward flow
trgPixNSub(:,1:2) = holePix.sub(:,1:2) + flowVec;
trgPixNSub(:, 3)  = holePix.sub(:,3)   + frameInc;

% Check if the flow neighbors are valid
uvValidInd = vc_check_index_limit(trgPixNSub, [imgW, imgH, nFrame]);
uvValidInd = uvValidInd & (holePix.bdInd ~= bdLabel);

% ========================================================================================
% Compute flow weights
% ========================================================================================
trgPixNIntSub = round(trgPixNSub(uvValidInd,:));  % Flow neighbor position in subscript
trgPixNInd    = sub2ind([imgH, imgW, nFrame], ... % Flow neighbor position in index
    trgPixNIntSub(:,2), trgPixNIntSub(:,1), trgPixNIntSub(:,3));

% Use distance-based weights
fWeightTemp = opt.alphaT.^(-distMap(trgPixNInd));
fWeight = 4*max(opt.minLambdaFlowT, fWeightTemp);

fWeight = 1;

% Compute flow weight
flowWeight(uvValidInd) = fWeight;

end