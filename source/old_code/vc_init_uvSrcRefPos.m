function uvTrgRefPos = vc_init_uvSrcRefPos(NNF, opt, videoFlow, useFlowGuidedSyn)

[imgH, imgW, nCh, nFrame, nFlow] = size(videoFlow);

% uvSrcRefPos = zeros(opt.pNumPix, 2, NNF.uvPix.numUvPix);
[X, Y] = meshgrid(-opt.pRad:opt.pRad, -opt.pRad:opt.pRad);

if(useFlowGuidedSyn)
    % Prepare the source patch reference positions
    nFrameN = opt.pSize-1;
    Spx = repmat(X(:), nFrameN, 1);
    Spy = repmat(Y(:), nFrameN, 1);
    St = cat(1, -2*ones(opt.pSize*opt.pSize, 1), ...
                -1*ones(opt.pSize*opt.pSize, 1), ...
                 1*ones(opt.pSize*opt.pSize, 1), ...
                 2*ones(opt.pSize*opt.pSize, 1));
    Sf = cat(1, 3*ones(opt.pSize*opt.pSize, 1), ...
                1*ones(opt.pSize*opt.pSize, 1), ...
                2*ones(opt.pSize*opt.pSize, 1), ...
                4*ones(opt.pSize*opt.pSize, 1));
    
    Sx = cat(2, Spx, Spy,   ones(opt.pSize*opt.pSize*nFrameN, 1), St, Sf);
    Sy = cat(2, Spx, Spy, 2*ones(opt.pSize*opt.pSize*nFrameN, 1), St, Sf);
    
    Strg = zeros(1, 5, NNF.uvPix.numUvPix);
    Strg(1, 1, :) = NNF.uvPix.sub(:,1);
    Strg(1, 2, :) = NNF.uvPix.sub(:,2);
    Strg(1, 4, :) = NNF.uvPix.sub(:,3);
    
    % Shift to target patch centers
    S_SubX = bsxfun(@plus, Sx, Strg);
    S_SubY = bsxfun(@plus, Sy, Strg);
    
    S_indX = sub2ind([imgH, imgW, nCh, nFrame, nFlow], ...
        S_SubX(:,2,:), S_SubX(:,1,:), S_SubX(:,3,:), S_SubX(:,4,:), S_SubX(:,5,:));
    S_indY = sub2ind([imgH, imgW, nCh, nFrame, nFlow], ...
        S_SubY(:,2,:), S_SubY(:,1,:), S_SubY(:,3,:), S_SubY(:,4,:), S_SubY(:,5,:));
    S_indX = squeeze(S_indX);
    S_indY = squeeze(S_indY);
    
    % Sample in optical flow field
    vx = videoFlow(S_indX);
    vy = videoFlow(S_indY);
    
    % Add the current frame
    vx_p = zeros(opt.pNumPix, NNF.uvPix.numUvPix);
    vy_p = zeros(opt.pNumPix, NNF.uvPix.numUvPix);
    
    vx_p(1:opt.pSize*opt.pSize*2,:) = vx(1:opt.pSize*opt.pSize*2,:);
    vx_p(end-opt.pSize*opt.pSize*2+1:end,:) = vx(end-opt.pSize*opt.pSize*2+1:end,:);
    
    vy_p(1:opt.pSize*opt.pSize*2,:) = vy(1:opt.pSize*opt.pSize*2, :);
    vy_p(end-opt.pSize*opt.pSize*2+1:end,:) = vy(end-opt.pSize*opt.pSize*2+1:end, :);

    % Add the patch positions
    vx = bsxfun(@plus, vx_p, repmat(X(:), opt.pSize, 1));
    vy = bsxfun(@plus, vy_p, repmat(Y(:), opt.pSize, 1));
    
    vx = reshape(vx, opt.pNumPix, 1, NNF.uvPix.numUvPix);
    vy = reshape(vy, opt.pNumPix, 1, NNF.uvPix.numUvPix);
    
    uvSrcRefPos = cat(2, vx, vy);
else
    refPos = cat(2, X(:), Y(:));
    uvSrcRefPos = repmat(refPos, opt.pSize, 1, NNF.uvPix.numUvPix);
end
uvSrcRefPos = single(uvSrcRefPos);

end