function videoBlend = vc_poisson_blend(videoTrg, videoSrc, holeMask, dim)

nCh    = size(videoTrg, 3);
nFrame = size(videoTrg, 4);

% Initialization
videoBlend = zeros(size(videoTrg), 'single');

warning('off','all');

if(dim == 2) % Poisson blending at each frame
    for i = 1: nFrame
        holeMaskCur = holeMask(:,:,i);
        imgTrg      = videoTrg(:,:,:,i);
        imgSrc      = videoSrc(:,:,:,i);
        videoBlend(:,:,:,i) = sc_poisson_blend(imgTrg, imgSrc, holeMaskCur);
    end
elseif(dim == 3)
    for iCh = 1: nCh
        videoTrgCur = squeeze(videoTrg(:,:,iCh,:));
        videoSrcCur = squeeze(videoSrc(:,:,iCh,:));
        videoBlend(:,:,iCh,:) = video_poisson_blend(videoTrgCur, videoSrcCur, holeMask);
    end
else
    error('The dimension should be 2 or 3');
end

end

function videoBlend = video_poisson_blend(videoTrg, videoSrc, holeMask)

[imgH, imgW, nFrame] = size(holeMask);

% Prepare 3D discrete Poisson equation
[A, b] = prepPoissonEqn3D(holeMask, videoTrg, videoSrc);

% solve Poisson equation
x = A\b;
videoRec = reshape(x, [imgH, imgW, nFrame]);

% Combined with the known region in the target
videoBlend = holeMask.*videoRec + ~holeMask.*videoTrg;

end

function [A, b] = prepPoissonEqn3D(holeMask, videoTrg, videoSrc)
% Prepare the linear system of equations for Poisson blending

[imgH, imgW, nFrame] = size(holeMask);
N = imgH*imgW*nFrame;

% Number of unknown variables
numUnknownPix = sum(holeMask(:));

maxNumInd = 8*numUnknownPix; % Max number of indices for constructing the sparse matrix
maxNumEqn = 6*numUnknownPix; % Max number of equations (4-neighbor)

% 6-neighbors: dx, dy, dt
dx = [1, 0, -1,  0, 0, 0];    
dy = [0, 1,  0, -1, 0, 0];
dt = [0, 0,  0,  0, 1,-1];

% ==============================================================
% Initialization
% ==============================================================

% Initialize (I, J, S), for sparse matrix A where A(I(k), J(k)) = S(k)
I = zeros(maxNumInd, 1);
J = zeros(maxNumInd, 1);
S = zeros(maxNumInd, 1);

% Initialize b
b = zeros(maxNumEqn, 1);

% Precompute unkonwn pixel position
pind = find(holeMask == 1);
[pi, pj, pk] = ind2sub([imgH, imgW, nFrame], pind);

% Precompute the 6-neighbor of the unkonwn pixel positions
qi = bsxfun(@plus, pi, dy);
qj = bsxfun(@plus, pj, dx);
qk = bsxfun(@plus, pk, dt);

% Handling cases at image borders
validN = (qi >= 1) & (qi <= imgH) & ...
    (qj >= 1) & (qj <= imgW) & (qk >= 1) & (qk <= nFrame);
qind = zeros(size(validN), 'single');
qind(validN) = sub2ind([imgH, imgW, nFrame], ...
    qi(validN), qj(validN), qk(validN));

% ==============================================================
% Set up the matrix A and the vector b
% ==============================================================
c = 1; % index counter for matrix A
e = 1; % equation counter

for k = 1: numUnknownPix
    pind_cur = pind(k);
    for n = 1: 4 % 4-neighbor
        if(validN(k, n)) % if the neighbor pixel q lies in the image
            qind_cur = qind(k, n);
            if(holeMask(qind_cur))
                % A(e, pind_cur) = 1;
                I(c) = e;   J(c) = pind_cur;    S(c) = 1;   c = c + 1;
                % A(e, qind_cur) = 1;
                I(c) = e;   J(c) = qind_cur;    S(c) = -1;  c = c + 1;
                
                % gradient constraint
                b(e) = videoSrc(pind_cur) - videoSrc(qind_cur);
                e = e + 1;
            else
                % A(e, pind_cur) = 1;
                I(c) = e;   J(c) = pind_cur;    S(c) = 1;   c = c + 1;
                
                % boundary constraint
                b(e) = videoSrc(pind_cur) - videoSrc(qind_cur) + videoTrg(qind_cur);
                e = e + 1;
            end
        end
    end
    % Temporal gradient
    w = 1;
    for n = 5:6
        if(validN(k, n)) % if the neighbor pixel q lies in the image
            qind_cur = qind(k, n);
            
            if(holeMask(qind_cur))
                % A(e, pind_cur) = 1;
                I(c) = e;   J(c) = pind_cur;    S(c) = w;   c = c + 1;
                % A(e, qind_cur) = 1;
                I(c) = e;   J(c) = qind_cur;    S(c) = -w;  c = c + 1;
                
                % gradient constraint
                b(e) = w*(videoSrc(pind_cur) - videoSrc(qind_cur));
                e = e + 1;
            else
                % A(e, pind_cur) = 1;
                I(c) = e;   J(c) = pind_cur;    S(c) = 1;   c = c + 1;
                
                % boundary constraint
                b(e) = videoSrc(pind_cur) - videoSrc(qind_cur) + videoTrg(qind_cur);
                e = e + 1;
            end
        end
    end
    
    
end

% Clean up unused entries
nEqn = e - 1;
b = b(1:e-1);

nInd = c - 1;
I = I(1:nInd);  J = J(1:nInd);  S = S(1:nInd);

% Construct the sparse matrix A
A = sparse(I, J, S, nEqn, N);

end