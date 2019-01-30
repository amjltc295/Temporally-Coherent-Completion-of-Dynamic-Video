function videoFlow = vc_syn_flow(videoSize, type)

% Synthesize optical flow of video size with type
% type
%  1: translational
%  2: translational, acceleration
%  3: rotation

% Size of the flowData
imgH = videoSize(1);
imgW = videoSize(2);
nFrame = videoSize(4);          % number of frame
nCh = 2;                        % [dx, dy]
nFlow = 2;                      % [forward, backward]


% Synthesize videoFlow
videoFlow = zeros(imgH, imgW, nCh, nFrame, nFlow, 'single');

videoNoise = 0*randn(size(videoFlow));
%
if(type == 1)
    % Constant translation
    dx = 1;
    dy = 2;
    videoFlow(:, :, 1, :, 1) = dx;
    videoFlow(:, :, 2, :, 1) = dy;
    videoFlow(:, :, 1, :, 2) = -dx;
    videoFlow(:, :, 2, :, 2) = -dy;
elseif(type == 2)
    % Spatially varying motion field
    [X, Y] = meshgrid(1:imgW, 1:imgH);
    maxMv = 10;
    X = maxDx*(X/imgW);
    Y = maxMv*(Y/imgH);
    videoFlow(:, :, 1, :, 1) = X(:,:,ones(nFrame,1));
    videoFlow(:, :, 2, :, 1) = Y(:,:,ones(nFrame,1));
    videoFlow(:, :, 1, :, 1) = -X(:,:,ones(nFrame,1));
    videoFlow(:, :, 2, :, 1) = -Y(:,:,ones(nFrame,1));
    
elseif(type == 3)
    % Rotational motion field
    [X, Y] = meshgrid(1:imgW, 1:imgH);

    maxMv = 10;
    % Around center
    d = sqrt((imgW/2).^2 + (imgH/2).^2);

    X = X - imgW/2;    Y = Y - imgH/2;
    X = maxMv*(X/d);   Y = maxMv*(Y/d);
    
    R = sqrt(X.^2 + Y.^2);
    theta = atan2(Y, X) + pi/2;
    
    dx = R.*cos(theta);
    dy = R.*sin(theta);
    videoFlow(:, :, 1, :, 1) = dx(:,:,ones(nFrame, 1));
    videoFlow(:, :, 2, :, 1) = dy(:,:,ones(nFrame, 1));
    videoFlow(:, :, 1, :, 2) = -dx(:,:,ones(nFrame, 1));
    videoFlow(:, :, 2, :, 2) = -dy(:,:,ones(nFrame, 1));
end

videoFlow = videoFlow + videoNoise;


end