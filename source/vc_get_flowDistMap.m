function distMap  = vc_get_flowDistMap(videoFlow, holePix)

% Count the number shorstest path for the hole pixels

[imgH, imgW, ~, nFrame] = size(videoFlow);

% Initialization
initDist = nFrame;
distMap  = zeros(imgH, imgW, nFrame, 'single');
distMap(holePix.ind)  = nFrame;

labelMap = ones(imgH, imgW, nFrame, 'single');
labelMap(holePix.ind) = 0;

% Compute the connected components of the spatio-temporal hole
[L, numLabel] = bwlabeln(holePix.mask, 6);
ccLabels      = uint8(L(holePix.ind));

while(true)
    % 1. Find shortest distance to known regions along flows
    [distMap, labelMap] = findShortestDist(distMap, labelMap, videoFlow, holePix);
    
    % Check remaining isolated pixels
    labels  = distMap(holePix.ind) == initDist;
    if(sum(labels) == 0)
        break;          % If all hole pixels have a valid distance to the known region
    end
    
    % 2. Mark isolated pixels
    updateInd = markIsolatedPixel(distMap, holePix, ccLabels, numLabel, initDist);
    distMap(holePix.ind(updateInd))  = 0;
    labelMap(holePix.ind(updateInd)) = 1;
end

end


% =========================================================================
% Find shortest distance to the known pixels
% =========================================================================
function [distMap, labelMap] = findShortestDist(distMap, labelMap, videoFlow, holePix)

% Setting up
nFrame      = size(videoFlow, 4);        % Number of frames
frameIndSet = unique(holePix.sub(:,3))'; % Frame index set
numIter     = 1;                         % Number of iterations

videoFlowF     = videoFlow(:,:,1:2,:);
videoFlowB     = videoFlow(:,:,3:4,:);
videoFlowConfF = videoFlow(:,:,5, :) > 0.5;
videoFlowConfB = videoFlow(:,:,6, :) > 0.5;

for iter = 1: numIter
    
    % 1. === Find flow neighbors using forward flow ===
    frameIndSet = fliplr(frameIndSet);
    frameInc    = 1;            % Frame increment for forward flow
    for indFrame = frameIndSet
        if(indFrame == nFrame)  % When forward flow exist
            continue;
        end
        [distNew, labelNew, updateInd] = updateDistMap(distMap, labelMap, ...
            holePix, indFrame, videoFlowF, videoFlowConfF, frameInc);
        distMap(holePix.ind(updateInd))  = distNew;
        labelMap(holePix.ind(updateInd)) = labelNew;
    end
    
    % 2. === Find flow neighbors using backward flow ===
    frameIndSet = fliplr(frameIndSet);
    frameInc    = -1;           % Frame increment for backward flow
    for indFrame = frameIndSet
        if(indFrame == 1)  % When backward flow exist
            continue;
        end
        [distNew, labelNew, updateInd] = updateDistMap(distMap, labelMap, ...
            holePix, indFrame, videoFlowB, videoFlowConfB, frameInc);
        distMap(holePix.ind(updateInd))  = distNew;
        labelMap(holePix.ind(updateInd)) = labelNew;
    end
    
end

end

function [distNew, labelNew, updateInd] = ...
    updateDistMap(distMap, labelMap, holePix, indFrame, videoFlow, videoFlowConf, frameInc)

[imgH, imgW, ~, nFrame] = size(videoFlow);

% Initialization
updateInd = [];
distNew   = [];
labelNew  = [];

% Index of the hole pixels at the current frame
indCur = find(holePix.sub(:,3) == indFrame);

% Find the flow neighbor position
holePixFnSub = vc_get_flow_neightbor(videoFlow, holePix.indF(indCur,:), ...
    holePix.sub(indCur,:), frameInc);

% =======================================================================================
% Check the the flow neighbors are valid
% =======================================================================================
validPosInd  = vc_check_index_limit(holePixFnSub, [imgW, imgH, nFrame]);
validFlowInd = videoFlowConf(holePix.ind(indCur));
validInd     = validPosInd & validFlowInd;

holePixFnSub = holePixFnSub(validInd,:);
indCur       = indCur(validInd);
distCur      = distMap(holePix.ind(indCur));

% =======================================================================================
% Check the flow neighbor to determine the distance increment
% =======================================================================================
dInc = vgg_interp2(labelMap(:,:,indFrame + frameInc), ...
    holePixFnSub(:,1), holePixFnSub(:,2), 'linear', 0);

distMapCur = distMap(:,:,indFrame + frameInc);

% =======================================================================================
% Check if the new distance is smaller than the current one
% =======================================================================================
% Case I: [1]: the flow neighbor has a valid distance
validDistInd = dInc == 1;
if(sum(validDistInd)) % Direct valid neighbor
    % Current index and current distance
    distCur_d = distCur(validDistInd);
    indCur_d  = indCur(validDistInd);

    % Candidate distance
    distN_d     = vgg_interp2(distMapCur, ...
        holePixFnSub(validDistInd,1), holePixFnSub(validDistInd,2), 'linear', 0) + 1;
    updateInd_d = distN_d  < distCur_d;
        
    indCur_d = indCur_d(updateInd_d);
    distN_d  = distN_d(updateInd_d);

    % Save the update index, distance, and label
    updateInd = cat(1, updateInd, indCur_d);
    distNew   = cat(1, distNew,   distN_d);
    labelNew  = cat(1, labelNew, ones(size(distN_d,1),1));
end

% Case II: (0.5, 1): the flow neighbor is at the border of label and unlabeled pixels
validBdInd   = (dInc > 0.5) & (dInc < 1);
if(sum(validBdInd)) % The flow neighbors are at boarders of known and unknown pixels
    % Current index and current distance
    indCur_b  = indCur(validBdInd);
    distCur_b = distCur(validBdInd);
    dInc      = dInc(validBdInd);
    
    % Candidate distance
    holePixFnSubInt = round(holePixFnSub(validBdInd, 1:2));
    holePixFnIndInt = sub2ind([imgH, imgW], holePixFnSubInt(:,2), holePixFnSubInt(:,1));
    
    distN_b  = distMapCur(holePixFnIndInt) + 1;
    
    updateInd_b = distN_b < distCur_b;
    
    indCur_b = indCur_b(updateInd_b);
    distN_b  = distN_b(updateInd_b);
    dInc     = dInc(updateInd_b);
    
    updateInd = cat(1, updateInd, indCur_b);
    distNew   = cat(1, distNew,   distN_b);
    labelNew  = cat(1, labelNew,  dInc);
end
end