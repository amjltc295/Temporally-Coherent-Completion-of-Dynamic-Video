function NNF = vc_init_lvl_nnf(holeMask, NNF, opt)

% 
% Prepare distance distMap
holeMaskInv = ~holeMask;
distMap = zeros(size(holeMaskInv), 'single');
for i = 1: size(distMap, 3)
    distMap(:,:,i) = bwdist(holeMaskInv(:,:,i), 'euclidean');
end

% Initialize the NNF for the current level
if(opt.iLvl == opt.numPyrLvl) % Initialization at the coarsest level
    % Initialize the NNF for the coarest level using random sampling
    NNF = vc_init_nnf(holeMask, opt);
else 
    % Initialize the NNF upsampling of NNF from previous level
    NNF = vc_upsample(videoFlow, holeMask, NNF, opt);
end

% Initialize the patch weights
[NNF.wPatchS, NNF.wVideoSum] = ...
    vc_prep_weight_patch(distMap, NNF.uvPix.sub, NNF.uvTrgRefPos, NNF.trgPatchInd, opt);


end

