function [uvCost, uvSrcTfrmFw, uvSrcTfrmBw] = ...
    vc_patch_cost(trgPatch, srcPatch, bdPatchInd, opt)
% VC_PATCH_COST: Compute patch matching cost
%
% Input:
%   - trgPatch:     target patch   [spPatchSize] x [nCh] x [numUvPix] (color: nCh = 3, color+gradient: nCh = 5)
%   - meanTrgPatch: mean target patch        [1] x [nCh] x [numUvPix] (color: nCh = 3, color+gradient: nCh = 5)
%   - srcPatch:     source patch   [spPatchSize] x [nCh] x [numUvPix] (color: nCh = 3, color+gradient: nCh = 5)
%   - wPatchS:      spatial patch weight [spPatchSize] x [numUvPix]
%   - bdPatchInd:   patches at temporal boundaries
%   - opt:          parameters
% Output:
%   - uvCost:       computed patch cost
%   - uvSrcTfmP:    photometric compensation
%   - uvSrcTfrmFw:  range transformation for forward flow vectors   [numUvPix] x 4
%   - uvSrcTfrmBw:  range transformation for backward flow vectors  [numUvPix] x 4
% =========================================================================

% Indices for color, gradient, forward and backward flow
colorInd  = [1, 2, 3];
flowFwInd = [4, 5];
flowBwInd = [6, 7];

% =========================================================================
% Compute color-based costs
% =========================================================================
srcPatchColor  = srcPatch(:,colorInd,:);
trgPatchColor  = trgPatch(:,colorInd,:);

% Compute appearance costs
uvCostColor = compute_patch_cost(trgPatchColor, srcPatchColor, opt.wPatchM);
uvCost      = opt.lambdaColor*uvCostColor;

% =========================================================================
% Compute flow-based costs
% =========================================================================
numUvPix    = size(trgPatch, 3);
uvSrcTfrmFw = zeros(numUvPix, 2, 'single');
uvSrcTfrmBw = zeros(numUvPix, 2, 'single');

numUvPix = size(srcPatch, 3);
if(numUvPix == 0)
    return;
end

if(opt.useFwFlow)
    % Forward flow transformation
    trgPatchF  = trgPatch(:,flowFwInd,:);
    srcPatchF  = srcPatch(:,flowFwInd,:);
    
    % Estimate transformation
    trgPixF    = trgPatchF(opt.pMidPix, :, :);
    srcPixF    = srcPatchF(opt.pMidPix, :, :);
    
    uvSrcTfrmFw = compute_sim_tform_2d(trgPixF, srcPixF);
    
    % Compute flow patch cost
%     srcPatchF  = vc_apply_flow_tform(uvSrcTfrmFw, srcPatchF);
%     uvCostFlow = compute_patch_cost(trgPatchF, srcPatchF, opt.wPatchM);
%     uvCost = uvCost + opt.lambdaFlow*uvCostFlow.*(bdPatchInd ~= 2);
end

if(opt.useBwFlow)
    % Backward flow transformation
    srcPatchF  = srcPatch(:,flowBwInd,:);
    trgPatchF  = trgPatch(:,flowBwInd,:);
    
    % Estimate transformation
    trgPixF    = trgPatchF(opt.pMidPix, :, :);
    srcPixF    = srcPatchF(opt.pMidPix, :, :);
    
    uvSrcTfrmBw = compute_sim_tform_2d(trgPixF, srcPixF);
    
    % Compute flow patch cost
%     srcPatchF  = vc_apply_flow_tform(uvSrcTfrmBw, srcPatchF);
%     uvCostFlow = compute_patch_cost(trgPatchF, srcPatchF, opt.wPatchM);
%     uvCost = uvCost + opt.lambdaFlow*uvCostFlow.*(bdPatchInd ~= 1);
end

end

function patchCost = compute_patch_cost(patchT, patchS, weightM)

patchCost = (patchT - patchS).^2;
patchCost = sum(sum(bsxfun(@times, weightM, patchCost), 1), 2);
patchCost = squeeze(patchCost);

end

function sTform = compute_sim_tform_2d(trgPixF, srcPixF)
% COMPUTE_SIM_TFORM_2D
% Compute the 2D similarity transformation that maps srcFlow to trgFlow
% sTform = [numUvPix] x [4]. Each row captures scale, rotation and mean
% source flow dx, dy

numUvPix = size(trgPixF, 3);
sTform   = zeros(numUvPix, 2, 'single');

% Compute scale and rotation
ST = srcPixF(1,[1,2,1,2],:).*trgPixF(1,[1,1,2,2],:);

trST = ST(1,1,:) + ST(1,4,:);
rtST = ST(1,2,:) - ST(1,3,:);

trSS = sum(srcPixF.^2, 2);

% Compute scale
sTform(:,1) = sqrt(trST.^2 + rtST.^2)./(trSS+eps);

% Rotation
sTform(:,2) = atan2(rtST, trST);

end

% function [uvSrcTfrm, uvCostFlow] = compute_tform_flow(trgPatch, srcPatch, opt)
% 
% % Compute flow transformation
% uvSrcTfrm = vc_compute_sim_tform(trgPatch, srcPatch, opt);
% 
% % Apply flow transformation
% srcPatchTfm = vc_apply_flow_tform(uvSrcTfrm, srcPatch);
% 
% % Compute distance
% uvCostFlow = [];
% % uvCostFlow = (trgPatch - srcPatchTfm).^2;
% % uvCostFlow = sum(sum(bsxfun(@times, wPatchM, uvCostFlow), 1), 2);
% % uvCostFlow = squeeze(uvCostFlow);
% 
% end
% 
% function sTform = vc_compute_sim_tform(trgFlow, srcFlow, opt)
% 
% % Compute the 2D similarity transformation that maps srcFlow to trgFlow
% % sTform = [numUvPix] x [4]. Each row captures scale, rotation and mean
% % source flow dx, dy
% %
% numUvPix = size(trgFlow, 3);
% sTform   = zeros(numUvPix, 2, 'single');
% 
% % Compute scale and rotation
% ST = sum(srcFlow(:,[1,2,1,2],:).*trgFlow(:,[1,1,2,2],:), 1);
% 
% trST = ST(1,1,:) + ST(1,4,:);
% rtST = ST(1,2,:) - ST(1,3,:);
% 
% trSS = sum(sum(srcFlow.^2, 1), 2);
% 
% % Compute scale
% sTform(:,1) = sqrt(trST.^2 + rtST.^2)./(trSS+eps);
% sTform(:,1) = vc_clamp(sTform(:,1), opt.minFlowScale, opt.maxFlowScale);
% 
% % Rotation
% sTform(:,2) = atan2(rtST, trST);
% 
% end