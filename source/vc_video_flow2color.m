function videoFlowRGB = vc_video_flow2color(videoFlow)

[imgH, imgW, nCh, nFrame] = size(videoFlow);

% Remove the forward flow in the last frame
videoFlow(:,:,:,end) = 0; 

% Compute the maximum flow in the video
videoFlowX = videoFlow(:,:,1,:);
videoFlowY = videoFlow(:,:,2,:);
flowRad = sqrt(videoFlowX.^2 + videoFlowY.^2);
flowRad = max(flowRad(:));

videoFlowRGB = zeros(imgH, imgW, 3, nFrame-1);
for i = 1: nFrame - 1
    img = flowToColor(videoFlow(:,:,1:2,i), flowRad);
    videoFlowRGB(:,:,:,i) = im2double(img);
end

end