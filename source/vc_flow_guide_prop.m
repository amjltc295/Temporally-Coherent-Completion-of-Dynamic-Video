function uvTCand = vc_flow_guide_prop(uvTCand, videoFlow, forward_backward)

%%

%%
% forward_backward = 1; % foward
% forward_backward = -1; % backward
% videoFlow(:,:,:,:,1:2));

[imgH, imgW, ~, nFrame, ~] = size(videoFlow);
uvTCandInt = int32(uvTCand);

uvTCandInt(:, 1) = vc_clamp(uvTCandInt(:,2), 1, imgW);
uvTCandInt(:, 2) = vc_clamp(uvTCandInt(:,2), 1, imgH);
uvTCandInt(:, 3) = vc_clamp(uvTCandInt(:,3), 1, nFrame);

uvTCandIntInd = sub2ind([imgH, imgW, nFrame], ...
    uvTCandInt(:,2), uvTCandInt(:,1), uvTCandInt(:,3));

if(forward_backward == 1) % forward propagation
    vx = videoFlow(:,:,1,:,1);
    vy = videoFlow(:,:,2,:,1);
    vt = 1;
else % backward propagation
    vx = videoFlow(:,:,1,:,2);
    vy = videoFlow(:,:,2,:,2);
    vt = -1;
end
vx = squeeze(vx);
vy = squeeze(vy);
uvPixVx = vx(uvTCandIntInd);
uvPixVy = vy(uvTCandIntInd);

uvPixDir = cat(2, uvPixVx, uvPixVy, vt*ones(size(uvTCandInt, 1), 1, 'single'));

uvTCand = uvTCand + uvPixDir;

end