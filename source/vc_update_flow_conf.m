function flowConf = vc_update_flow_conf(videoFlow, holePix, sigmaF)

interpolationKernel = 'linear';

flowFwInd   = 1:2;
flowBwInd   = 3:4;

% Grab the current flow vectors
flowFw     = videoFlow(holePix.indFt(:,:,1));
flowBw     = videoFlow(holePix.indFt(:,:,2));

% Get flow neighbors
trgPixSubFw = holePix.sub;
trgPixSubBw = holePix.sub;
trgPixSubFw(:,1:2) = trgPixSubFw(:,1:2) + flowFw;
trgPixSubBw(:,1:2) = trgPixSubBw(:,1:2) + flowBw;
trgPixSubFw(:,3)   = trgPixSubFw(:,3)   + 1;
trgPixSubBw(:,3)   = trgPixSubBw(:,3)   - 1;

% Compute flow confidence
flowFwBw   = vc_interp3(videoFlow(:,:,flowBwInd, :), trgPixSubFw, interpolationKernel);
flowBwFw   = vc_interp3(videoFlow(:,:,flowFwInd, :), trgPixSubBw, interpolationKernel);
flowConfFw = sum((flowFw + flowFwBw).^2, 2);
flowConfBw = sum((flowBw + flowBwFw).^2, 2);
flowConfFw = exp(-flowConfFw/(2*sigmaF.^2));
flowConfBw = exp(-flowConfBw/(2*sigmaF.^2));

flowConf = cat(2, flowConfFw, flowConfBw);

end
