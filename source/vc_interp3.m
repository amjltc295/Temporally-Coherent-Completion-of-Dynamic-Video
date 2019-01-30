function data = vc_interp3(V, p, interpolationKernel)

% V: H x W x nCh x nFrame
% p:   N x 3
% data: N x nCh

if(ndims(V) == 4)
    [imgH, imgW, nCh, nFrame] = size(V);
elseif(ndims(V)==3)
    [imgH, imgW, nFrame] = size(V);
    V = reshape(V, [imgH, imgW, 1, nFrame]);
    nCh = 1;
end

N    = size(p, 1);
data = zeros(N, nCh, 'single');

for iFrame = 1 : nFrame
    if(iFrame < 1 || iFrame > nFrame)
        continue;
    end
    
    % Current frame
    indCurFrame = (p(:,3) == iFrame);
    
    % Interpolation
    data(indCurFrame, :) = vgg_interp2(V(:,:,:, iFrame), ...
        p(indCurFrame,1), p(indCurFrame,2), interpolationKernel, 0);
end

end
