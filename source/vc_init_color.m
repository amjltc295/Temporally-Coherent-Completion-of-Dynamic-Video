function videoColor = vc_init_color(videoColor, videoFlow, holeMask, opt)

% VC_INIT_COLOR: Flow-based diffusion for initializing colors

% Spatial color diffusion
videoColor = vc_init_completion(videoColor, holeMask, 2);

% =========================================================================
% Get flow neighbors
% =========================================================================
% Get the target pixels
[~, NNF.holePix, ~, ~] = vc_get_trgPix(holeMask, opt.pSize);

% Update flow confidence
sigmaF = 1;
videoFlow(NNF.holePix.indFt(:,:,3)) = vc_update_flow_conf(videoFlow, NNF.holePix, sigmaF);

% Find flow neighbors
flowNN = vc_get_flowNN(videoFlow, NNF.holePix);

% =========================================================================
% Temporal color diffusion
% =========================================================================
interpolationKernel = 'bicubic';
indValid = flowNN(:,3) ~= 0;

% Temporal flow neighbor
colorDataFn   = vc_interp3(videoColor, flowNN(indValid, :), interpolationKernel);

videoColor(NNF.holePix.indC(indValid,:)) = colorDataFn;


end