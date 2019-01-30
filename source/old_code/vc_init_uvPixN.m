function uvPixN = vc_init_trgPixN(NNF, opt)
% VC_INIT_UVPIXN
% 
% Precompute the target patch neighbors
% 
% 
uvPixN = cell(6, 1);
for i = 1:6
    uvPixN{i}.sub = bsxfun(@minus, NNF.uvPix.sub, opt.propDir(i,:));
end

% Get ind and validInd
for i = 1:6
    % Check if the neighbors go out of matrix limit
    validInd = vc_check_index_limit(uvPixN{i}.sub, [NNF.imgW, NNF.imgH, NNF.nFrame]);    
    uvPixNSub = uvPixN{i}.sub(validInd,:);
    
    % Get the index
    uvPixN{i}.ind = ones(NNF.uvPix.numUvPix, 1, 'single');
    uvPixN{i}.ind(validInd) = sub2ind([NNF.imgH, NNF.imgW, NNF.nFrame], ...
        uvPixNSub(:,2), uvPixNSub(:,1), uvPixNSub(:,3));
    uvPixN{i}.validInd = NNF.uvPix.mask(uvPixN{i}.ind);
end

end