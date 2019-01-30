function holePixN = vc_init_holePixN(holePix, invalidFlowMask, videoSize, propDir)

numNeighbor = 4;
holePixN    = cell(numNeighbor, 1);

% Video size
imgH   = videoSize(1);
imgW   = videoSize(2);
nFrame = videoSize(3);

videoInd = zeros(videoSize, 'single');
videoInd(holePix.ind) = 1: holePix.numPix;

for i = 1: numNeighbor
    % === Get the (x,y,t) positions of the spatial neighbors ===
    holePixN{i}.sub = bsxfun(@minus, holePix.sub, propDir(i,:));
    
    % Check if the neighbors go out of matrix limit
    validInd = vc_check_index_limit(holePixN{i}.sub, [imgW, imgH, nFrame]);
    holePixNSub = holePixN{i}.sub(validInd,:);
       
    % === Get the vInd: vectorized index position for the neighbor ===
    holePixNInd = sub2ind(videoSize, holePixNSub(:,2), holePixNSub(:,1), holePixNSub(:,3));
    
    vInd = videoInd(holePixNInd);
    
    % hole pixel AND valid flow
    validNeighborInd = (vInd ~= 0) & ~invalidFlowMask(holePixNInd);                      
    
    holePixN{i}.vInd = vInd(validNeighborInd);
    
    % === Get the validInd: binary vector for valid index ===
    validPos = find(validInd);
    validPos = validPos(~validNeighborInd);
    validInd(validPos) = 0;
    holePixN{i}.validInd = validInd;
end

end