function videoG = vc_compute_grad(videoL)

% VC_COMPUTE_GRAD: compute x- y- gradient of the video
% Input:
%   - videoL: the luminance channel of the video [imgH] x [imgW] x [nFrame] 
%
% Output:
%   - videoG: the gradient x and y [imgH] x [imgW] x [2] x [nFrame]

fprintf('Computing gradients \n');

videoL = squeeze(videoL);
[imgH, imgW, nFrame] = size(videoL);

tic;
[videoGx, videoGy] = gradient2(videoL);

videoGx = reshape(videoGx, [imgH, imgW, 1, nFrame]);
videoGy = reshape(videoGy, [imgH, imgW, 1, nFrame]);

videoG = cat(3, videoGx, videoGy);
t = toc;

fprintf('%30sdone in %.03f seconds \n', '', t);

end