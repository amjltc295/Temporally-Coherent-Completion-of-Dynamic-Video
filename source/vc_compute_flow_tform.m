function [srcTfmFw, srcTfmBw] = vc_compute_flow_tform(videoFlowFwBw, trgPos, srcPos)
    
trgFlow = vc_interp3(videoFlowFwBw, trgPos);
srcFlow = vc_interp3(videoFlowFwBw, srcPos);

srcTfmFw = compute_sim_tform_2d(trgFlow(:,1:2), srcFlow(:,1:2));
srcTfmBw = compute_sim_tform_2d(trgFlow(:,3:4), srcFlow(:,3:4));


end


function sTform = compute_sim_tform_2d(trgPixF, srcPixF)
% COMPUTE_SIM_TFORM_2D
% Compute the 2D similarity transformation that maps srcFlow to trgFlow
% sTform = [numUvPix] x [4]. Each row captures scale, rotation and mean
% source flow dx, dy

numUvPix = size(trgPixF, 1);
sTform   = zeros(numUvPix, 2, 'single');

% Compute scale and rotation
ST = srcPixF(:,[1,2,1,2]).*trgPixF(:,[1,1,2,2]);

trST = ST(:,1) + ST(:,4);
rtST = ST(:,2) - ST(:,3);

trSS = sum(srcPixF.^2, 2);

% Compute scale
sTform(:,1) = sqrt(trST.^2 + rtST.^2)./(trSS + eps);

% Rotation
sTform(:,2) = atan2(rtST, trST);

end
