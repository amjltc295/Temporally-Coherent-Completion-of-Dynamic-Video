function y = vc_check_index_limit(x, xLimit)

% x: [N] x [3]
% sizeVideo: [imgW] x [imgH] x [nFrame]

y = x(:,1) >=1 & x(:,1) <= xLimit(1) & ...
    x(:,2) >=1 & x(:,2) <= xLimit(2) & ...
    x(:,3) >=1 & x(:,3) <= xLimit(3);

end