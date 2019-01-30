function data = vc_video_sub2data(V, p)

% V: H x W x nCh x nFrame
% p:   N x 3
% data: N x nCh

[imgH, imgW, nCh, nFrame] = size(V);
N = size(p, 1);

ind = zeros(N, nCh, 'int64');
for i = 1: nCh
    ind(:,i) = sub2ind([imgH, imgW, nCh, nFrame], p(:,2), p(:,1), i*ones(N, 1), p(:,3));
end

data = V(ind);

end