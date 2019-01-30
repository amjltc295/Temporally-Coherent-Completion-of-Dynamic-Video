function C = vc_multiply_tform_matrix(A, B)
% Multiple two set of affine matrices
% 
% Each row in A, B, and C is the 4 affine transformation parameters
% This function allows batch multiplication without looping through each
% pair of 2D affine transformation matrix
%
% Input:
%   - A: a matrix of afine transformation parameters [N] x [4]
%   - B: a matrix of afine transformation parameters [N] x [4]
% Output: 
%   - C: a matrix of afine transformation parameters [N] x [4]
%     The i-th row of C is computed from 
%     reshape(A(:,i),2,2) * reshape(B(:,i),2,2)
%

C = zeros(size(A), 'single');

C(:,1:2) = bsxfun(@times, A(:, 1:2), B(:,1)) + bsxfun(@times, A(:, 3:4), B(:,2));
C(:,3:4) = bsxfun(@times, A(:, 1:2), B(:,3)) + bsxfun(@times, A(:, 3:4), B(:,4));

end