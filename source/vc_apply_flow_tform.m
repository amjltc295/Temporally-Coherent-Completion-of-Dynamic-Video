function srcFlowTform = vc_apply_flow_tform(sTform, srcFlow)
%
% VC_APPLY_FLOW_TFORM: Apply the similarity transform sTform to the srcFlow
%
% Input:
%   - sTform:      similarity transformation        [numUvPix] x [4]
%   - srcFlow:     source patch flow       [spPatchSize] x [2] x [numUvPix]

numUvPix = size(srcFlow, 3);

% Construct similarity transformation matrix
s_cos = sTform(:,1).*cos(sTform(:,2));
s_sin = sTform(:,1).*sin(sTform(:,2));
s_cos = reshape(s_cos, [1, 1, numUvPix]);
s_sin = reshape(s_sin, [1, 1, numUvPix]);

% Compute transformed flow
srcFlowTformX = sum(bsxfun(@times, srcFlow, cat(2,   s_cos,  s_sin)), 2);
srcFlowTformY = sum(bsxfun(@times, srcFlow, cat(2,  -s_sin,  s_cos)), 2);
srcFlowTform = cat(2, srcFlowTformX, srcFlowTformY);

end
