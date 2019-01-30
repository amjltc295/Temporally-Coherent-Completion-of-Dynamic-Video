function [uvCost, uvFlowTformT] = vc_patch_cost_flow(trgPatch, srcPatch, videoFlow, ...
    uvFlowTformA, uvPixSub, wPatchST, uvRefPos, opt)

%%

%%
[spPatchSize, nCh, nFlow, numUvPix] = size(srcPatch);

% === Apply the uvFlowTform to the srcPatch ===
srcPatchT = vc_apply_flow_tform(srcPatch, uvFlowTformA);

% Apply the translations
meanTrgPatch = mean(trgPatch, 1);
meanSrcPatch = mean(srcPatchT, 1);

% Compute bias and clamp it to inteval [optS.minBias, optS.maxBias]
offsetPatch = meanTrgPatch - meanSrcPatch;
offsetPatch = vc_clamp(offsetPatch, opt.minFlowOffset, opt.maxFlowOffset);
uvFlowTformT = squeeze(offsetPatch);

% Apply flow offset
srcPatch  = bsxfun(@plus, srcPatchT, offsetPatch);

% === Compute patch appearance cost: L1 cost ===
patchDistApp = abs(bsxfun(@minus, trgPatch, srcPatch));
patchDistApp = bsxfun(@times, patchDistApp, wPatchST(:,1,1,:));

% patchDistApp = reshape(patchDistApp, [spPatchSize*nCh*nFlow, numUvPix]);

% === Compute Forward-backward compatibility ===
% || Mb(t_i + Mf(s_i)) + Mf(s_i)|| 
% || Mf(t_i + Mb(s_i)) + Mb(s_i)|| 

% Compute the forward and backward flow neighbors of uvPixSub
flowF = squeeze(srcPatch(opt.pMidPix,:,1,:));
flowB = squeeze(srcPatch(opt.pMidPix,:,2,:));

flowF = cat(2, flowF',  ones(numUvPix, 1, 'single'));
flowB = cat(2, flowB', -ones(numUvPix, 1, 'single'));

uvPixSubF = bsxfun(@plus, uvPixSub, flowF);
uvPixSubB = bsxfun(@plus, uvPixSub, flowB);

% Sample the backward flow field using the forward neighbors
flowPatchB = vc_prep_flow_patch(videoFlow, uvPixSubF, uvRefPos);

% Sample the forward flow field using the backward neighbors
flowPatchF =  vc_prep_flow_patch(videoFlow, uvPixSubB, uvRefPos);

flowPatch = cat(3, flowPatchB(:,:,2,:), flowPatchF(:,:,1,:));

patchDistTemporal = abs(flowPatch + srcPatch);
patchDistTemporal(:,:,1,:) = bsxfun(@times, patchDistTemporal(:,:,1,:), wPatchST(:,3,1,:));
patchDistTemporal(:,:,2,:) = bsxfun(@times, patchDistTemporal(:,:,2,:), wPatchST(:,2,1,:));

% === Combine two types of costs ===
patchDist = patchDistApp + patchDistTemporal;
patchDist = reshape(patchDist, [spPatchSize*nCh*nFlow, numUvPix]);
uvCost = sum(patchDist, 1)';

end