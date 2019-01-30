function srcPos = vc_get_temporal_propagation(srcPos, videoFlow, propDir)

% Initialize the flow vector at the source position
interpolationKernel = 'linear';
srcPosFlow = vc_interp3(videoFlow, srcPos, interpolationKernel);

% The flow neighbor
srcPos(:,1:2) = srcPos(:,1:2) + srcPosFlow;
srcPos(:,  3) = srcPos(:,  3) + propDir;

end
