function [flowDataF, flowDataB] = vc_update_flow(videoColor, videoFlow, holePixF, holePixN)

% Given the estimated color, update the flow

% Frame increment for forward and backward flow
frameIncF  =  1;
frameIncB  = -1;

% Update forward flow
flowDataF = solveFlowCG(videoColor, videoFlow(:,:,1:2,:), ...
    frameIncF, holePixF, holePixN);

% Update backward flow
flowDataB = solveFlowCG(videoColor, videoFlow(:,:,3:4,:), ...
    frameIncB, holePixF, holePixN);

end

function flowData = solveFlowCG(videoColor, videoFlow, frameInc, holePixF, holePixN)

% Optical flow estimation parameters
nOuterFPIterations = 10;
nCGIterations      = 20;      % Number of iterations for the congugate gradient algorithm
alpha              = 0.25;     % Flow Regularization term

[imgH, imgW, ~, nFrame] = size(videoColor);

% The color data of the hole pixels
colorData1    = videoColor(holePixF.indC);

% Initial flow vectors
u = videoFlow(holePixF.indF(:,1));
v = videoFlow(holePixF.indF(:,2));

for i = 1:nOuterFPIterations
    % ===========================================================================
    % Computer image gradients (dx, dy, dt)
    % ===========================================================================
    holePixSubN  = holePixF.sub;
    holePixSubN(:,1) = holePixSubN(:,1) + u;
    holePixSubN(:,2) = holePixSubN(:,2) + v;
    holePixSubN(:,3) = holePixSubN(:,3) + frameInc;
    
    validPixInd = vc_check_index_limit(holePixSubN, [imgW, imgH, nFrame]);
    
    % Temporal gradient
    colorData2  = vc_interp3(videoColor, holePixSubN, 'cubic');
    colorDataGt = colorData2 - colorData1;
    
    % Spatial gradient
    colorDataM = (colorData1 + colorData2)/2;
    [colorDataGx, colorDataGy]= getGradient(colorDataM, holePixN);

    % ===========================================================================
    % Update the weights
    % ===========================================================================
    weightPhi = getPhi(u, v, holePixN);
    weightPsi = getPsi(colorDataGt);
    
    % ===========================================================================
    % Set up the linear system
    % ===========================================================================
    % Form matrix A
    A11 = sum(weightPsi.*colorDataGx.*colorDataGx, 2);
    A22 = sum(weightPsi.*colorDataGy.*colorDataGy, 2);
    A12 = sum(weightPsi.*colorDataGx.*colorDataGy, 2);

    A11 = A11 + 0.5*alpha;
    A22 = A22 + 0.5*alpha;
    
    % Form b
    r1  = sum(weightPsi.*colorDataGx.*colorDataGt, 2);
    r2  = sum(weightPsi.*colorDataGy.*colorDataGt, 2);

    flowDataUL = computeLaplacian(u, weightPhi, holePixN);
    flowDataVL = computeLaplacian(v, weightPhi, holePixN);

    r1 = - r1 - alpha*flowDataUL;
    r2 = - r2 - alpha*flowDataVL;
    
    % ===========================================================================
    % Run CG iterations
    % ===========================================================================
    % Initialization
    du     = zeros(size(u), 'single');
    dv     = zeros(size(v), 'single');
    
    % Enforece the boundary constraints of flow field
    invalidInd = holePixF.indB | ~validPixInd;

    rou = zeros(nCGIterations, 1);
    for k = 1: nCGIterations
        r1(invalidInd) = 0;
        r2(invalidInd) = 0;

        rou(k) = r1'*r1 + r2'*r2;
        if(k == 1)
            p1 = r1;
            p2 = r2;
        else
            ratio = rou(k)/(rou(k-1) + eps);
            p1 = r1 + ratio*p1;
            p2 = r2 + ratio*p2;
        end
        Lp1 = computeLaplacian(p1, weightPhi, holePixN);
        Ap1 = A11.*p1 + A12.*p2 + alpha*Lp1;
        
        Lp2 = computeLaplacian(p2, weightPhi, holePixN);
        Ap2 = A12.*p1 + A22.*p2 + alpha*Lp2;
        
        beta = rou(k)/(p1'*Ap1 + p2'*Ap2 + eps);
        
        % Update
        du = du + beta*p1;
        dv = dv + beta*p2;
        
        r1 = r1 - beta*Ap1;
        r2 = r2 - beta*Ap2;
    end
    
    % ===========================================================================
    %  Update the estimate flow field
    % ===========================================================================
    u = u + du;
    v = v + dv;

%     videoFlow(holePixF.indF) = cat(2, u, v);
%     figure(4); imagesc(videoFlow(:,:,1,2), [-1,1]); colorbar;
%     videoFlow(holePixF.indF) = cat(2, u0, v0);
%     figure(5); imagesc(videoFlow(:,:,1,2), [-1,1]); colorbar;
end

flowData = cat(2, u(holePixF.indS), v(holePixF.indS));

end

function [gx, gy]= getGradient(x, holePixN)

gx = zeros(size(x), 'single');
gy = zeros(size(x), 'single');

% x-derivative
indN = 3;
validInd = holePixN{indN}.validInd;
% neighborInd = holePixN{indN}.vInd(validInd);
neighborInd = holePixN{indN}.vInd;
gx(validInd,:) = x(neighborInd,:) - x(validInd,:);

% y-derivative
indN = 4;
validInd = holePixN{indN}.validInd;
neighborInd = holePixN{indN}.vInd;
gy(validInd,:) = x(neighborInd,:) - x(validInd,:);

end

function xL = computeLaplacian(x0, w0, holePixN)

xL = zeros(size(x0), 'single');

% Get valid neighbor index
vInd = cell(4,1);
for i = 1:4
    vInd{i} = holePixN{i}.vInd;
end

% Get weight
w1 = w0(vInd{1});
w2 = w0(vInd{2});

% Left
indN = 1;
validInd = holePixN{indN}.validInd;
x1 = x0(vInd{indN});
xL(validInd) = xL(validInd) + w1.*( x0(validInd) - x1);

% Top
indN = 2;
validInd = holePixN{indN}.validInd;
x2 = x0(vInd{indN});
xL(validInd) = xL(validInd) + w2.*( x0(validInd) - x2);

% Right
indN = 3;
validInd = holePixN{indN}.validInd;
x3 = x0(vInd{indN});
xL(validInd) = xL(validInd) + w0(validInd).*( x0(validInd) - x3);

% Down
indN = 4;
validInd = holePixN{indN}.validInd;
x4 = x0(vInd{indN});
xL(validInd) = xL(validInd) + w0(validInd).*( x0(validInd) - x4);

end

function phiData = getPhi(u, v, holePixN)

eps_phi = 1e-6;
[ux, uy] = getGradient(u, holePixN);
[vx, vy] = getGradient(v, holePixN);

phiData = ux.^2 + uy.^2 + vx.^2 + vy.^2;
phiData = 0.5./sqrt(phiData + eps_phi);

end


function psiData = getPsi(imdt)

eps_psi = 1e-6;
psiData = 0.5./sqrt(imdt.^2 + eps_psi);

end