function patchCost = vc_patch_cost_app(patchT, patchS, weightM)

patchCost = (patchT - patchS).^2;                 % L2 cost
% patchCost = abs(patchT - patchS);               % L1 cost

patchCost = sum(sum(bsxfun(@times, patchCost, weightM), 1), 2);
patchCost = squeeze(patchCost);

end