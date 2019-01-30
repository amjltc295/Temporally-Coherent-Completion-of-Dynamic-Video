function vc_vis_flow_neighbor(videoData, videoFlow, holeMask, opt)

[imgH, imgW, nCh, nFrame, nFlow] = size(videoFlow);

videoData = im2double(videoData);
videoFlow = double(videoFlow);

% =========================================================================
% Visualize flow neighbor
% =========================================================================
flowNPath = fullfile(opt.visResPath, 'flow_neighbor');
if(~exist(flowNPath, 'dir'))
    mkdir(flowNPath);
end

% 
videoData = im2single(videoData);

holeMaskC = logical(makeMaskCh(holeMask, 3));
videoData(holeMaskC) = 0.0;

for iFrame = 1:nFrame
    img = videoData(:,:,:, iFrame);
    fwFlowCur = videoFlow(:,:,:,iFrame,1);
    bwFlowCur = videoFlow(:,:,:,iFrame,2);
    
    % Get mask
    holeMaskCur = holeMask(:,:,iFrame);
        
    % HolePixIndF
    holePixInd = find(holeMaskCur);
    HolePixIndF = cat(2, holePixInd, holePixInd + imgH*imgW);

    numHolePix = size(holePixInd, 1);
    
    % Get holePix
    [r,c] = ind2sub([imgH, imgW], holePixInd);
    holePixSub = cat(2, c, r, iFrame*ones(numHolePix, 1));
    
    % FlowVec
    fwFlowVec  = fwFlowCur(HolePixIndF);
    bwFlowVec  = bwFlowCur(HolePixIndF);
    
    if(iFrame ~= 1)          % Backward flow exisit
        bwFlowNPixSub = holePixSub;
        bwFlowNPixSub(:,1:2) = holePixSub(:,1:2) + bwFlowVec;
        bwFlowNPixSub(:,3)   = bwFlowNPixSub(:,3)  - 1;
        
        % backward flow neighbor
        bwFlowNPixSub = round(bwFlowNPixSub);
        validInd = vc_check_index_limit(bwFlowNPixSub, [imgW, imgH, nFrame]);
        bwFlowNPixInd = ones(numHolePix, 1);
        
        bwFlowNPixInd(validInd) = sub2ind([imgH, imgW, nFrame], ...
            bwFlowNPixSub(validInd,2), bwFlowNPixSub(validInd,1), ...
            bwFlowNPixSub(validInd,3));
        
        knownPixSub = holePixSub(~holeMask(bwFlowNPixInd),:);
        knownPixInd = sub2ind([imgH, imgW], knownPixSub(:,2), knownPixSub(:,1));
        knownPixInd = knownPixInd + imgH*imgW;
        % Labeled as green
        img(knownPixInd) = 1;  
    end
    
    if(iFrame ~= nFrame) % Forward flow exisit
        fwFlowNPixSub = holePixSub;
        fwFlowNPixSub(:,1:2) = holePixSub(:,1:2) + fwFlowVec;
        fwFlowNPixSub(:,3)   = fwFlowNPixSub(:,3)  + 1;

        % forward flow neighbor
        fwFlowNPixSub = round(fwFlowNPixSub);
        validInd = vc_check_index_limit(fwFlowNPixSub, [imgW, imgH, nFrame]);
        fwFlowNPixInd = ones(numHolePix, 1);
        
        fwFlowNPixInd(validInd) = sub2ind([imgH, imgW, nFrame], ...
            fwFlowNPixSub(validInd,2), fwFlowNPixSub(validInd,1), ...
            fwFlowNPixSub(validInd,3));

        knownPixSub = holePixSub(~holeMask(fwFlowNPixInd),:);
        knownPixInd = sub2ind([imgH, imgW], knownPixSub(:,2), knownPixSub(:,1));
        
        % Labeled as red
        img(knownPixInd) = 1; 
    end
    
    % Save files
    imgName = [opt.videoName, '_', num2str(iFrame, '%03d'), '.png'];
    imwrite(img,  fullfile(flowNPath,  imgName));
    
end

end

function x = makeMaskCh(x, nCh)

[imgH, imgW, nFrame] = size(x);
x = reshape(x, [imgH, imgW, 1, nFrame]);
x = x(:,:,ones(nCh, 1), :);

end