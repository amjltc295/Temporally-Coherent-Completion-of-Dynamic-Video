function map = vc_update_uvMap(map, data, uvPixInd)

% Update the NNF uvMap

[imgH, imgW, nFrame, nCh] = size(map);

offset = int64((0:nCh-1)*imgH*imgW*nFrame);

uvPixInd = bsxfun(@plus, uvPixInd, offset);
map(uvPixInd) = data;

end