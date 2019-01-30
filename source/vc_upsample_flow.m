% =========================================================================
% Upsample flow from the previous level
% =========================================================================

function videoFlow = vc_upsample_flow(NNF, videoFlowOld, videoFlow)

interpolationKernel = 'linear';

% Size of low-resolution and high-resolution video
[imgH_LR, imgW_LR, ~,~ ] = size(videoFlowOld);
[imgH_HR, imgW_HR, ~, ~] = size(videoFlow);

% Scaling flow vectors
sX = imgW_LR/imgW_HR;
sY = imgH_LR/imgH_HR;

% The hole pixel position in the LR video.
holePixSub = NNF.holePix.sub*diag([sX, sY, 1]);

% Get the estimated flow from the previous level
flowUpScale = reshape(1./[sX, sY, sX, sY], [1,4]);
flowDataUpsample = vc_interp3(videoFlowOld(:,:,1:4,:), holePixSub, interpolationKernel);
flowDataUpsample = bsxfun(@times, flowDataUpsample, flowUpScale);

% Update the flow values
videoFlow(NNF.holePix.indFt(:,:,1:2)) = flowDataUpsample;

end
