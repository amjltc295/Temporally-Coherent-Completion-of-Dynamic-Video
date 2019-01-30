function flowNN = vc_get_flowNN(videoFlow, holePix)

% Assign each hole pixel its flow-based nearest neighbor
% (with the shortest geodesic distance)

% flowNN: [numPix] x [3] (dx, dy, dt)

% Initialization
flowNN = zeros(holePix.numPix, 3, 2,  'single');

[imgH, imgW, ~, nFrame] = size(videoFlow);

% Initialization
initDist = nFrame;
distMapF  = zeros(imgH, imgW, nFrame, 'single');
distMapB  = zeros(imgH, imgW, nFrame, 'single');

distMapF(holePix.ind)  = initDist;
distMapB(holePix.ind)  = initDist;

% Compute the connected components of the spatio-temporal hole
[L, numLabel] = bwlabeln(holePix.mask, 6);
ccLabels      = uint8(L(holePix.ind));

% Flow representation
videoFlowF     = videoFlow(:,:,1:2,:);
videoFlowB     = videoFlow(:,:,3:4,:);
videoFlowConfF = videoFlow(:,:,5, :) > 0.5;
videoFlowConfB = videoFlow(:,:,6, :) > 0.5;

frameIndSetF = unique(holePix.sub(:,3))';
frameIndSetB = fliplr(frameIndSetF);

while(true)
    % =========================================================================
    % Find shortest distance to known regions along flow vectors
    % =========================================================================
    % 1. Propagate backward (use forward flow)
    frameInc = 1;
    for indFrame = frameIndSetB
        % Skip when forward flow exist
        if(indFrame == nFrame)
            continue;
        end
        % Get the new flowNN and distMap
        [updateInd, distCand, flowNNCand] = ...
            updateFlowNN(videoFlowF, videoFlowConfF, distMapF, holePix, ...
            flowNN(:,:,1), indFrame, frameInc);
        % Update
        flowNN(updateInd, :, 1) = flowNNCand;
        distMapF(holePix.ind(updateInd)) = distCand;
    end
    
    % 2. Propagate forward (use backward flow)
    frameInc = -1;
    for indFrame = frameIndSetF
        % Skip when backward flow exist
        if(indFrame == 1)
            continue;
        end
        % Get the new flowNN and distMap
        [updateInd, distCand, flowNNCand] = ...
            updateFlowNN(videoFlowB, videoFlowConfB, distMapB, holePix, ...
            flowNN(:,:,2), indFrame, frameInc);
        % Update
        flowNN(updateInd, :, 2) = flowNNCand;
        distMapB(holePix.ind(updateInd)) = distCand;
    end
    
    % =========================================================================
    % Mark isolated pixels
    % =========================================================================
    % Check remaining isolated pixels
    isolatePixInd  = (distMapF(holePix.ind) == initDist) & ...
        (distMapB(holePix.ind) == initDist);
    if(sum(isolatePixInd) == 0)
        % If all hole pixels have a valid distance to the known region
        break;
    end
    % Mark isolated pixels
    distMap   = min(distMapF, distMapB);
    updateInd = markIsolatedPixel(distMap, holePix, ccLabels, numLabel, initDist);
    distMapF(holePix.ind(updateInd))  = 0;
    distMapB(holePix.ind(updateInd))  = 0;
end

end

function [updatePos, distCand, flowNNCand] = ...
    updateFlowNN(videoFlow, videoFlowConf, distMap, holePix, flowNN, indFrame, frameInc)

[imgH, imgW, ~, nFrame] = size(videoFlow);

% The hole pixel index at the current frame
indCur = find(holePix.sub(:,3) == indFrame);

% =========================================================================
% Remove invalid pixels
% =========================================================================

holePixFnSub = vc_get_flow_neightbor(videoFlow, holePix.indF(indCur,:), ...
    holePix.sub(indCur,:), frameInc);
validPosInd  = vc_check_index_limit(holePixFnSub, [imgW, imgH, nFrame]);
validFlowInd = videoFlowConf(holePix.ind(indCur));
validInd     = validPosInd & validFlowInd;

holePixFnSub = holePixFnSub(validInd,:);
indCur       = indCur(validInd);
distCur      = distMap(holePix.ind(indCur));

% =========================================================================
% Compare the current distance with the candidate distance
% =========================================================================
% Check the distance of the flow neighbor
holePixFnSubInt = round(holePixFnSub);
holePixFnInd    = sub2ind([imgH, imgW, nFrame], ...
    holePixFnSubInt(:,2), holePixFnSubInt(:,1), holePixFnSubInt(:,3));
distCand   = distMap(holePixFnInd) + 1;

% Update the flow-based distance
updateInd = distCand < distCur;

updatePos    = indCur(updateInd);
distCand     = distCand(updateInd);
holePixFnSub = holePixFnSub(updateInd,:);
holePixFnInd = holePixFnInd(updateInd);

% =========================================================================
% Compare the current distance with the candidate distance
% =========================================================================

% Update the flowNN:
flowNNCand = zeros(size(distCand,1), 3, 'single');
% - Case I: direct flow neigbhor
nnIndDirect  = distCand == 1;
if(sum(nnIndDirect) ~= 0)
    flowNNCand(nnIndDirect,:) = holePixFnSub(nnIndDirect, :);
end

% - Case II: indirect flow neigbhor
nnIndIndirect  = ~nnIndDirect;
if(sum(nnIndIndirect) ~= 0)
    % Get the flow neighbor of the indirect neighbor
    indFlowNN = holePix.indMap(holePixFnInd(nnIndIndirect));
    flowNN_n  = flowNN(indFlowNN, :);
    
    % Get the refinement vector
    refineVec = holePixFnSub(nnIndIndirect, :);
    refineVec = refineVec - round(refineVec);
    
    flowNNCand(nnIndIndirect, :) = flowNN_n + refineVec;
end

end
% =========================================================================
% Mask isolated pixels
% =========================================================================
function updateInd = markIsolatedPixel(distMap, holePix, ccLabels, numLabel, initDist)

nFrame = size(distMap, 3);

updateInd = false(holePix.numPix, 1);

for iLabel = 1: numLabel
    indCurLabel = ccLabels == iLabel;
    
    % Count which frame has the most number of unknownPix
%     isolatedPixInd = isolatePixInd(holePix.ind(indCurLabel));
    isolatedPixInd = distMap(holePix.ind(indCurLabel)) == initDist;
    nIsolatedPix = zeros(nFrame, 1);
    for indFrame = 1:nFrame
        indCur = holePix.sub(indCurLabel, 3) == indFrame;
        nIsolatedPix(indFrame) = sum(isolatedPixInd(indCur));
    end
    % Add bias toward the center frame
    % TO-DO: should consider only the temporal span of the hole
    h = fspecial('gaussian', [nFrame, 1], nFrame/2);
    nIsolatedPix = nIsolatedPix.*h;
    [~, keyframe] = max(nIsolatedPix);
    
    % Mark the isolated pixels at keyframe as known pixels
    indCurKeyframe = holePix.sub(indCurLabel, 3) == keyframe;
    updateInd(indCurLabel) = indCurKeyframe & isolatedPixInd;
end

end
