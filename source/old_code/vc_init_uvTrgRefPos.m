function uvTrgRefPos = vc_init_uvTrgRefPos(NNF, opt, videoFlow, useFlowGuidedSyn, flowFlag)


%%

%%
if(flowFlag)
    % uvTrgRefPos for flow completion: pSize*pSize x 2
    uvTrgRefPos = vc_init_uvTrgRefPos_flow(opt);
else
    % uvTrgRefPos for video completion: pSize*pSize*nFrame x 3 x numUvPix
    uvTrgRefPos = vc_init_uvTrgRefPos_video(NNF, opt, videoFlow, useFlowGuidedSyn);
end
uvTrgRefPos = single(uvTrgRefPos);

end

function uvTrgRefPos = vc_init_uvTrgRefPos_flow(opt)

% X Y positions
[X, Y] = meshgrid(-opt.pRad:opt.pRad, -opt.pRad:opt.pRad);
T = zeros(opt.spPatchSize, 1, 'single');
uvTrgRefPos = cat(2, X(:), Y(:), T);


end

function uvTrgRefPos = vc_init_uvTrgRefPos_video(NNF, opt, videoFlow, useFlowGuidedSyn)

if(useFlowGuidedSyn)
    [imgH, imgW, nCh, nFrame, nFlow] = size(videoFlow);
    spPatchSize = opt.spPatchSize;
    
    % X Y positions
    [X, Y] = meshgrid(-opt.pRad:opt.pRad, -opt.pRad:opt.pRad);
    
    % Prepare the target patch reference positions
    nFrameN = 2;
    Spx = repmat(X(:), nFrameN, 1);
    Spy = repmat(Y(:), nFrameN, 1);
    St  = zeros(opt.spPatchSize*nFrameN, 1);
    Sf = cat(1, 2*ones(spPatchSize, 1), ... % backward
        1*ones(spPatchSize, 1));            % foreward
    
    Sx = cat(2, Spx, Spy,   ones(spPatchSize*nFrameN, 1), St, Sf);
    Sy = cat(2, Spx, Spy, 2*ones(spPatchSize*nFrameN, 1), St, Sf);
    
    % Prepare target center positions
    Strg = zeros(1, 5, NNF.uvPix.numUvPix);
    Strg(1, 1, :) = NNF.uvPix.sub(:,1);
    Strg(1, 2, :) = NNF.uvPix.sub(:,2);
    Strg(1, 4, :) = NNF.uvPix.sub(:,3);
    
    % Shift the target patch reference positions to target patch centers
    S_SubX = bsxfun(@plus, Sx, Strg);
    S_SubY = bsxfun(@plus, Sy, Strg);
    
    % Sample the motion optical flow field
    S_indX = sub2ind([imgH, imgW, nCh, nFrame, nFlow], ...
        S_SubX(:,2,:), S_SubX(:,1,:), S_SubX(:,3,:), S_SubX(:,4,:), S_SubX(:,5,:));
    S_indY = sub2ind([imgH, imgW, nCh, nFrame, nFlow], ...
        S_SubY(:,2,:), S_SubY(:,1,:), S_SubY(:,3,:), S_SubY(:,4,:), S_SubY(:,5,:));
    S_indX = squeeze(S_indX);
    S_indY = squeeze(S_indY);
    
    vx = videoFlow(S_indX);
    vy = videoFlow(S_indY);
    
    vx_p = cat(1, zeros(spPatchSize, NNF.uvPix.numUvPix), vx);
    vy_p = cat(1, zeros(spPatchSize, NNF.uvPix.numUvPix), vy);
    
    % Patch positions
    vx = bsxfun(@plus, vx_p, repmat(X(:), nFrameN + 1, 1));
    vy = bsxfun(@plus, vy_p, repmat(Y(:), nFrameN + 1, 1));
    
    % Add time offsets
    vt = cat(1, zeros(spPatchSize, 1), -ones(spPatchSize, 1), ...
        ones(spPatchSize, 1));
    
    vt = repmat(vt, 1, NNF.uvPix.numUvPix);
    
    % Reshape them to pNumPix x 3 x numUvPix
    vx = reshape(vx, spPatchSize*(nFrameN+1), 1, NNF.uvPix.numUvPix);
    vy = reshape(vy, spPatchSize*(nFrameN+1), 1, NNF.uvPix.numUvPix);
    vt = reshape(vt, spPatchSize*(nFrameN+1), 1, NNF.uvPix.numUvPix);
    uvTrgRefPos = cat(2, vx, vy, vt);
else
    % X Y positions
    [X, Y, T] = meshgrid(-opt.pRad:opt.pRad, -opt.pRad:opt.pRad, -1:1);
    
    refPos = cat(2, X(:), Y(:), T(:));
    uvTrgRefPos = repmat(refPos, [1, 1, NNF.uvPix.numUvPix]);
end
end