function     uvMat = vc_uvMat_from_uvMap(uvMap, uvPixInd)

[imgH, imgW, nFrame, nCh] = size(uvMap);

uvPixInd = int64(uvPixInd);
offset   = int64((0:nCh-1)*imgH*imgW*nFrame);
uvPixInd = bsxfun(@plus, uvPixInd, offset);

uvMat    = uvMap(uvPixInd);

end