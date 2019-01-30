function y = vc_apply_affine_tform(A, x)

% Input: 
%   - A: affine transformation matrix  [N] x [4]
%   - x: 2D vectors                    [N] x [2]
% Output:
%   - y: transformed vector            [N] x [2]

y = bsxfun(@times, A(:,1:2), x(:,1)) + ...
    bsxfun(@times, A(:,3:4), x(:,2));

end