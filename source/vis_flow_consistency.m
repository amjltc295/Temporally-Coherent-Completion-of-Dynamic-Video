function vis_flow_consistency(videoName)

% videoName = 'MPI_sleeping_2';
%
opt = vc_init_opt(videoName);
% Load computed flow
flowDataFileName = fullfile(opt.flowDataPath, [videoName, '_flow.mat']);
videoFlow  = vc_compute_flow([], flowDataFileName);
videoFlowF = videoFlow(:,:,1:2,:);
videoFlowB = videoFlow(:,:,3:4,:);

[imgH, imgW, ~, nFrame] = size(videoFlow);

errFwBw = zeros(imgH, imgW, nFrame, 'single');
errBwFw = zeros(imgH, imgW, nFrame, 'single');

[X, Y]  = meshgrid(1: imgW, 1:imgH);

flowFwInc   =  1;
flowBwInc   = -1;

% ========================================================================================
% Compute flow errors
% ========================================================================================
for iFrame = 2:nFrame -1
    pCur = single(cat(2, X(:), Y(:), iFrame*ones(imgH*imgW, 1)));

    % === Compute forward-backward errors ===
    flowF = vc_interp3(videoFlowF, pCur);
   
    pFw    = pCur;
    pFw(:,1:2) = pFw(:,1:2) + flowF;
    pFw(:,3)   = pFw(:,3)   + flowFwInc;
    flowB = vc_interp3(videoFlowB, pFw);
    
    distFlow = sum((flowF + flowB).^2, 2);
    errFwBw(:,:,iFrame) = reshape(distFlow, imgH, imgW);
    
    % === Compute backward-forward errors ===
    flowB = vc_interp3(videoFlowB, pCur);
    
    pBw    = pCur;
    pBw(:,1:2) = pBw(:,1:2) + flowB;
    pBw(:,3)   = pBw(:,3)   + flowBwInc;
    flowF = vc_interp3(videoFlowF, pBw);
    
    distFlow = sum((flowF + flowB).^2, 2);
    errBwFw(:,:,iFrame) = reshape(distFlow, imgH, imgW);
end

sigmaF  = 1;
errFwBw = 1 - exp(-errFwBw/(2*sigmaF.^2));
errBwFw = 1 - exp(-errBwFw/(2*sigmaF.^2));

% ========================================================================================
% Visualize flow errors
% ========================================================================================
vc_export_video_vis(errFwBw, [], opt.visFlowErrResPath, [videoName, '_fErrFwBw_'], 'JetColor');
vc_export_video_vis(errBwFw, [], opt.visFlowErrResPath, [videoName, '_fErrBwFw_'], 'JetColor');

end