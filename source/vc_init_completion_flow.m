function videoFlowSyn = vc_init_completion_flow(videoFlow, holeMask)

nFrame = size(holeMask, 3);

% Dilate the object mask to avoid bad flow initialization
se = strel('square', 25);

if(0)
    flowFwInvalidMask = squeeze(videoFlow(:,:,5,:)) < 0.5;
    flowBwInvalidMask = squeeze(videoFlow(:,:,6,:)) < 0.5;
    flowFwInvalidMask(:,:,end) = 0;
    flowBwInvalidMask(:,:,1)   = 0;
    
    flowFwInvalidMask = flowFwInvalidMask | holeMask;
    flowBwInvalidMask = flowBwInvalidMask | holeMask;
    
    for i = 1:nFrame
        flowFwInvalidMask(:,:,i) = imfill(flowFwInvalidMask(:,:,i), 'hole');
        flowBwInvalidMask(:,:,i) = imfill(flowBwInvalidMask(:,:,i), 'hole');
    end
    
    flowFwInvalidMask = imdilate(flowFwInvalidMask, se);
    flowBwInvalidMask = imdilate(flowBwInvalidMask, se);
    
    videoFlowSyn  = videoFlow;
    
    videoFlowSyn(:,:,[1:2],:) = vc_init_completion(videoFlow(:,:,[1:2],:), flowFwInvalidMask, 2);
    videoFlowSyn(:,:,[3:4],:) = vc_init_completion(videoFlow(:,:,[3:4],:), flowBwInvalidMask, 2);
else
    
    holeMask = imdilate(holeMask, se);
    videoFlowSyn = vc_init_completion(videoFlow(:,:,:,:), holeMask, 2);
end
end