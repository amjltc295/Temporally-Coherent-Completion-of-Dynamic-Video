function Y  = vc_apply_affine_tform_patch(A, X)

% Input: 
%   - A: affine transformation matrix  [N] x [4]
%   - x: 2D vectors                    [K] x [2]
% Output:
%   - y: transformed vector            [K] x [2] x [N]

N = size(A, 1);
A = reshape(A', [1, 4, N]);

x = sum(bsxfun(@times, X, A(:,[1,3],:)), 2);
y = sum(bsxfun(@times, X, A(:,[2,4],:)), 2);

Y = cat(2, x, y);

end