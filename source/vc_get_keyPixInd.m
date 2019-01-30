function holePix = vc_get_keyPixInd(videoFlow, holePix)

% ====================================================================================
% Label each pixel as keypixel or non-keypixel
% ====================================================================================

nFrame = size(videoFlow, 4);            % Number of frames
keyPixMask = ~holePix.mask;             % Initialize keyPixMask

videoFlowF = videoFlow(:,:,:,:,1);      % Forward flow
videoFlowB = videoFlow(:,:,:,:,2);      % Backward flow

frameIndSet= unique(holePix.sub(:,3))'; % Frame index set

numIter = 4;
for iter = 1: numIter
    % Find flow neighbors using forward flow
    frameIndSet = fliplr(frameIndSet);
    for indFrame = frameIndSet
        if(indFrame ~= nFrame)  % Forward flow exist
            indCur = find(holePix.sub(:,3) == indFrame);
            holePixFwSub = vc_get_temporal_propagation(holePix.sub(indCur, :), ...
                videoFlowF, 1);
            knownPixInd = vc_check_valid_uv(holePixFwSub, keyPixMask);
            keyPixMask(holePix.ind(indCur(knownPixInd))) = 1;
        end
    end
    
    % Find flow neighbors using backward flow
    frameIndSet = fliplr(frameIndSet);
    for indFrame = frameIndSet
        if(indFrame ~= 1)  % Backward flow exist
            indCur = find(holePix.sub(:,3) == indFrame);
            holePixBwSub = vc_get_temporal_propagation(holePix.sub(indCur, :), ...
                videoFlowB, -1);
            knownPixInd = vc_check_valid_uv(holePixBwSub, keyPixMask);
            keyPixMask(holePix.ind(indCur(knownPixInd))) = 1;
        end
    end
end

% ====================================================================================
% Compute connected components of the 3D hole mask
% ====================================================================================
[L, numLabel] = bwlabeln(holePix.mask, 6);
holePix.label = uint8(L(holePix.ind));

% ====================================================================================
% Get keyframe and keyPixInd for each connected hole region
% ====================================================================================

% Unknown pixels
keyPixMask = ~keyPixMask;
keyPixInd  = zeros(holePix.numPix, 1, 'uint64');

keyframe   = zeros(numLabel, 1, 'uint64');
for iLabel = 1: numLabel
    indCurLabel = holePix.label == iLabel;
    
    keyPixIndCur  = keyPixMask(holePix.ind(indCurLabel));
    
    % Count which frame has the most number of unknownPix
    nUnknownPix = zeros(nFrame, 1);
    for indFrame = frameIndSet % (2:end-1)
        indCur = holePix.sub(indCurLabel,3) == indFrame;
        nUnknownPix(indFrame) = sum(keyPixIndCur(indCur));
    end
    % Identify keyframe
    [~, keyframe(iLabel)] = max(nUnknownPix);
    
    % Keep only keypixel at the keyframe
    nonKeyPixInd = holePix.sub(indCurLabel,3) ~= keyframe(iLabel);
    keyPixIndCur(nonKeyPixInd) = false;
    
    % Save the keyPixInd
    keyPixInd(indCurLabel) = keyPixIndCur;
    
    keyPixMask(holePix.ind(~keyPixIndCur)) = false;
end

% Save keyPixInd, keyPixMask, and keyframe
holePix.keyPixInd  = keyPixInd;
holePix.keyPixMask = keyPixMask;
holePix.keyframe   = keyframe;

end