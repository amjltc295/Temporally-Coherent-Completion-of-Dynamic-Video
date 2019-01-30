function videoFlow = vc_compute_flow(videoData, flowDataPath, frameInd)

% VC_COMPUTE_FLOW
% Input:
% - videoData: the video data of size [imgH] x [imgW] x [nCh] x [nFrame]
% - flowFileName: the file to cache the computed optical flow
%
% Output:

nFrame = size(videoData, 4);

startFrame = frameInd.start;
endFrame   = frameInd.start + nFrame - 1; %min(frameInd.end, nFrame);

fprintf('Loading optical flow data: \n');
tic;

flowFileName = fullfile(flowDataPath, ['flowFw_', num2str(1, '%04d'), '.mat']); % The first frame
if(~exist(flowFileName, 'file'))
    % === Initialize optical flow algorithm parameters ===
    alpha = 0.012;
    ratio = 0.75;
    minWidth = 20;
    nOuterFPIterations = 7;
    nInnerFPIterations = 1;
    nSORIterations = 30;
    
    para = [alpha,ratio,minWidth,nOuterFPIterations,nInnerFPIterations,nSORIterations];
    
    % === Compute optical flow for adjacent frames ===
    nFrame = size(videoData,4);
    % Forward and Backward flow
    incFw =  1;
    incBw = -1;
    videoFlowF = computeFlowVideo(videoData, 1 : nFrame-1,   incFw, para, flowDataPath);
    videoFlowB = computeFlowVideo(videoData, nFrame: -1 : 2, incBw, para, flowDataPath);
    
    % Convert to single and cache them
    videoFlowF = single(videoFlowF);
    videoFlowB = single(videoFlowB);
else
    % === Load results ===
    [imgH, imgW, ~, nFrameSel] = size(videoData);
    nFlowCh = 2;
    videoFlowF = zeros(imgH, imgW, nFlowCh, nFrameSel, 'single');
    videoFlowB = zeros(imgH, imgW, nFlowCh, nFrameSel, 'single');
    
    % Loading forward flow
    i = 1;
    for indFrame = startFrame: endFrame - 1
        flowFwName = fullfile(flowDataPath, ['flowFw_', num2str(indFrame, '%04d'), '.mat']);
        load(flowFwName);
        videoFlowF(:,:,:,i) = flowFw;
        i = i + 1;
    end
    % Loading backward flow
    i = 2;
    for indFrame = startFrame + 1: endFrame
        flowBwName = fullfile(flowDataPath, ['flowBw_', num2str(indFrame, '%04d'), '.mat']);
        load(flowBwName);
        videoFlowB(:,:,:,i) = flowBw;
        i = i + 1;
    end
    
end

% Compute flow confidence
videoFlowConf = computeFlowConf(videoFlowF, videoFlowB);

% Put forward and backward flow together
videoFlow = cat(3, videoFlowF, videoFlowB, videoFlowConf);

t = toc;
fprintf('%30sdone in %.03f seconds \n', '', t);

end

function videoFlow = computeFlowVideo(videoData, frameInd, inc, para, flowDataPath)

% Compute the optical flow for the video

[imgH, imgW, ~, nFrame] = size(videoData);
videoFlow = zeros(imgH, imgW, 2, nFrame, 'single');
if(sign(inc) > 0)
    fwbw     = 'forward';
    flowName = 'flowFw';
else
    fwbw     = 'backward';
    flowName = 'flowBw';
end

for j = frameInd
    flowFileName = fullfile(flowDataPath, [flowName, '_', num2str(j, '%04d'), '.mat']);
    if(~exist(flowFileName, 'file'))
        videoFrame1 = videoData(:,:,:,j);
        videoFrame2 = videoData(:,:,:,j + inc);
        
        tic;
        [videoFlow(:,:,1,j), videoFlow(:,:,2,j), ~] = ...
            Coarse2FineTwoFrames(videoFrame1, videoFrame2, para);
        tFrame = toc;
        
        maxFlow = sqrt(videoFlow(:,:,1,j).^2 + videoFlow(:,:,2,j).^2);
        maxFlow = max(maxFlow(:));
        
        disp(['Computing ', fwbw,' flow at frame ', num2str(j), '/', num2str(nFrame), ...
            ' in ', num2str(tFrame),  ' s. ', 'Max flow rad: ', num2str(maxFlow)]);
        
        % Save result
        if(sign(inc) > 0)
            flowFw = single(videoFlow(:,:,:,j));
            save(flowFileName, 'flowFw');
        else
            flowBw = single(videoFlow(:,:,:,j));
            save(flowFileName, 'flowBw');
        end
    end
end


end

function videoFlowConf = computeFlowConf(videoFlowF, videoFlowB)

[imgH, imgW, ~, nFrame] = size(videoFlowF);

errFwBw = zeros(imgH, imgW, nFrame, 'single');
errBwFw = zeros(imgH, imgW, nFrame, 'single');

[X, Y]  = meshgrid(1: imgW, 1:imgH);

flowFwInc   =  1;
flowBwInc   = -1;

% ========================================================================================
% Compute flow errors
% ========================================================================================
interpolationKernel = 'linear';

for iFrame = 1 : nFrame
    pCur = single(cat(2, X(:), Y(:), iFrame*ones(imgH*imgW, 1)));
    
    % === Compute forward-backward errors ===
    if(iFrame ~= nFrame)
        flowF = vc_interp3(videoFlowF, pCur, interpolationKernel);
        
        pFw    = pCur;
        pFw(:,1:2) = pFw(:,1:2) + flowF;
        pFw(:,3)   = pFw(:,3)   + flowFwInc;
        flowB = vc_interp3(videoFlowB, pFw, interpolationKernel);
        
        distFlow = sum((flowF + flowB).^2, 2);
        errFwBw(:,:,iFrame) = reshape(distFlow, imgH, imgW);
    end
    
    % === Compute backward-forward errors ===    
    if(iFrame ~= 1)
        flowB = vc_interp3(videoFlowB, pCur, interpolationKernel);
        
        pBw    = pCur;
        pBw(:,1:2) = pBw(:,1:2) + flowB;
        pBw(:,3)   = pBw(:,3)   + flowBwInc;
        flowF = vc_interp3(videoFlowF, pBw, interpolationKernel);
        
        distFlow = sum((flowF + flowB).^2, 2);
        errBwFw(:,:,iFrame) = reshape(distFlow, imgH, imgW);
    end    
end

% ========================================================================================
% Compute flow confidence
% ========================================================================================

% Compute flow confidence using flow consistency
sigmaF  = 0.5;
confFwBw = exp(-errFwBw/(2*sigmaF.^2));
confBwFw = exp(-errBwFw/(2*sigmaF.^2));

% Remove the first and the last frame
confFwBw(:,:,end) = 0;
confBwFw(:,:,1)   = 0;

% Reshape
confFwBw = reshape(confFwBw, [imgH, imgW, 1, nFrame]);
confBwFw = reshape(confBwFw, [imgH, imgW, 1, nFrame]);

% Combine forward-backward and backward-forward confidence
videoFlowConf = cat(3, confFwBw, confBwFw);

end