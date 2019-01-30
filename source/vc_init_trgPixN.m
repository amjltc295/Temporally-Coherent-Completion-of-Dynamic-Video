function trgPixN = vc_init_trgPixN(NNF, propDir, numNeighbor)
% VC_INIT_TRGPIXN
%
% Precompute the target patch neighbors
%
% Input:
%   - NNF: nearest neighbor field
%   - opt: algorithm parameters
% Ouput:
%   - trgPixN: spatial neighbors of target patches

trgPixN = cell(numNeighbor, 1);

for i = 1: numNeighbor
    % Get the (x,y,t) positions of the spatial neighbors
    trgPixN{i}.sub = bsxfun(@minus, NNF.trgPix.sub, propDir(i,:));
    
    % Check if the neighbors go out of matrix limit
    validInd = vc_check_index_limit(trgPixN{i}.sub, [NNF.imgW, NNF.imgH, NNF.nFrame]);
    trgPixNSub = trgPixN{i}.sub(validInd,:);
    
    % Get the index and valid ind
    trgPixN{i}.ind = ones(NNF.trgPix.numPix, 1, 'single');
    trgPixN{i}.ind(validInd) = sub2ind([NNF.imgH, NNF.imgW, NNF.nFrame], ...
        trgPixNSub(:,2), trgPixNSub(:,1), trgPixNSub(:,3));
    trgPixN{i}.validInd = NNF.trgPix.mask(trgPixN{i}.ind);
end

end