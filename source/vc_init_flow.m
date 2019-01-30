function videoFlowSyn  = vc_init_flow(videoFlow, holeMask)

% Inpaint the optical flow using 2D diffusion-based inpainting
% 

[imgH, imgW, nCh, nFrame] = size(videoFlow);
videoFlowSyn = videoFlow;

flowConfThres = 0.5;

fprintf('Initial flow inpainting: \n');
tic;
for iFrame = 1:nFrame
    % Get hole boundary pixel index
    holeMaskCur   = holeMask(:,:,iFrame);
    holeMaskBd    = xor(imdilate(holeMaskCur, strel('disk', 1)), holeMaskCur);
    holeMaskBdInd = find(holeMaskBd);
      
    % Filling forward flow
    if(iFrame ~= nFrame)
        videoFlowFwConf = videoFlow(:,:,5,iFrame);
        flowFwConf = videoFlowFwConf(holeMaskBd) < flowConfThres;
        invalidFlowFwInd = holeMaskBdInd(flowFwConf);
        for iCh = 1:2
            videoFlowCur = squeeze(videoFlow(:,:,iCh,iFrame));
            videoFlowCur(invalidFlowFwInd) = 0;
            videoFlowSyn(:,:,iCh,iFrame) = regionfill(videoFlowCur, holeMaskCur);
        end
    end
    
    % Filling backward flow
    if(iFrame ~= 1)
        videoFlowBwConf = videoFlow(:,:,6,iFrame);
        flowBwConf = videoFlowBwConf(holeMaskBd) < flowConfThres;
        invalidFlowBwInd = holeMaskBdInd(flowBwConf);
        for iCh = 3:4
            videoFlowCur = squeeze(videoFlow(:,:,iCh,iFrame));
            videoFlowCur(invalidFlowBwInd) = 0;
            videoFlowSyn(:,:,iCh,iFrame) = regionfill(videoFlowCur, holeMaskCur);
        end
    end
end
t = toc;
fprintf('%30sdone in %.03f seconds \n', '',t);

end