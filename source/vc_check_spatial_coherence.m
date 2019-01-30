function uvActiveInd = vc_check_spatial_coherence(srcPosMap, srcTfrmGMap, trgInd, trgIndN, srcPos, opt)

% Check target pixels that are not spatially coherent

% Active pixels for random search
uvActiveInd = false(size(trgInd,1), 1);

% The geometric transform of the source patch
srcTfrmG = vc_uvMat_from_uvMap(srcTfrmGMap, trgInd);

for i = opt.spatialPropInd
    v = -opt.propDir(i,:);
    
    % source patch of the neighbors
    srcPosN = vc_uvMat_from_uvMap(srcPosMap,  trgIndN{i}.ind);
    
    % predicted source patch position
    srcPosP = vc_get_spatial_propagation(srcPos, srcTfrmG, v);
    
    % check if the prediction is correct
    dist = sum(abs(srcPosN - srcPosP), 2);
    indActive = dist > 1;
    uvActiveInd(indActive) = 1;
end

end