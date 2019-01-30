function tform = vc_compute_affine_2d(P, Q)

% VC_COMPUTE_AFFINE_2D

% Compute affine transformation from 2D point sets
% Input: 
%   - P: [K] x [2] x [N]
%   - Q: [K] x [2] x [N]
% Ouput:
%   - tform: [N] x [4]

% Naive implementation
% tic;
% tform1 = vc_compute_affine_2d_s(P, Q);
% t1 = toc;

% Faster implementation
tform = vc_compute_affine_2d_p(P, Q);

end

function tform = vc_compute_affine_2d_p(P, Q)

numPix = size(P, 3);

% Compute inv(P'P)
PtP_11  = sum(P(:,1,:).*P(:,1,:), 1);
PtP_22  = sum(P(:,2,:).*P(:,2,:), 1);
PtP_12  = sum(P(:,1,:).*P(:,2,:), 1);

PtP_det = PtP_11.*PtP_22 - PtP_12.^2 + eps;
PtPinv  = cat(4, PtP_22, -PtP_12, -PtP_12, PtP_11);
PtPinv  = bsxfun(@rdivide, PtPinv, PtP_det);

% Compute P'Q
PtQ_11 = sum(P(:,1,:).*Q(:,1,:), 1);
PtQ_21 = sum(P(:,2,:).*Q(:,1,:), 1);
PtQ_12 = sum(P(:,1,:).*Q(:,2,:), 1);
PtQ_22 = sum(P(:,2,:).*Q(:,2,:), 1);

PtQ    = cat(4, PtQ_11, PtQ_21, PtQ_12, PtQ_22);

PtPinv = reshape(PtPinv, numPix, 4);
PtQ    = reshape(PtQ,    numPix, 4);
% Compute tform
tform = vc_multiply_tform_matrix(PtPinv, PtQ);

% Transpose
tform(:,[2,3])= deal(tform(:,[3,2]));

end

function tform = vc_compute_affine_2d_s(P, Q)

K = size(P, 1);
N = size(P, 3);

tform = zeros(N, 4, 'single');

for i = 1: N
    Pcur = P(:,:,i);
    Qcur = Q(:,:,i);
    
    A = (Pcur\Qcur)';
    tform(i,:) = A(:);
end

end
