function trgPixSub  = vc_get_flow_neightbor(videoFlow, trgPixIndF, trgPixSub, frameInc)

% VC_GET_FLOW_NEIGHBOR

% Get flow vectors
flowVec  = videoFlow(trgPixIndF);

% Add flow vectors from the forward flow
trgPixSub(:,1:2) = trgPixSub(:,1:2) + flowVec;
trgPixSub(:, 3)  = trgPixSub(:,3)   + frameInc;

end
