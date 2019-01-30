% function cost = vc_patch_cost_coherence(srcPosMap, dtMap, trgPos, srcPos, srcTfmG, opt)
function cost = vc_patch_cost_coherence(srcPosMap, trgPixN, srcPos, uvValidPos, opt)

% VC_PATCH_COST_COHERENCE
%
% Spatial coherence cost
%
% Input
%   - srcPosMap: source patch map [imgH] x [imgW] x [nFrame] [3]
%   - trgPos:    target patch positions [numPix] x [3]
%   - srcPos:    source patch positions [numPix] x [3]
%   - srcTfmG:   source patch geometric transformation [numPix] x [4]
%   - opt:       parameters
% Output:
%   - cost:      spatio-temporal coherence cost

% [imgH, imgW, nFrame, ~] = size(srcPosMap);

% initialize coherence cost
numPix = size(uvValidPos,1);
cost   = zeros(numPix, 1, 'single');

for i = opt.spatialPropInd
    if(size(uvValidPos, 1) == 0)
        continue;
    end
    trgIndN = trgPixN{i}.ind(uvValidPos);
    srcPosN = vc_uvMat_from_uvMap(srcPosMap,  trgIndN);
       
    incohInd  = srcPosN(:,3) ~= srcPos(:,3);
    
    cost = cost + incohInd;
    
end

cost = opt.lambdaCoherence*single(cost);

end