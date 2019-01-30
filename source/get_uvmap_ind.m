function uvMapInd = get_uvmap_ind(mapSize, uvPixInd)

offset = int64((0:mapSize(4)-1)*prod(mapSize(1:3)));
uvMapInd = bsxfun(@plus, uvPixInd, offset);

end