function [videoFlow, NNF] = vc_init_lvl_nnf_flow(videoFlow, holeMask, NNF, iLvl, opt)


%%

%%
% Prepare distance weight
holeMaskInv = ~holeMask;
distMap = zeros(size(holeMaskInv), 'single');
for i = 1: size(distMap, 3)
    distMap(:,:,i) = bwdist(holeMaskInv(:,:,i), 'euclidean');
end

if(iLvl == opt.numPyrLvl) % Initialization at the coarsest level
    % Initialize the NNF for the coarest level using random sampling
    
    % CODE CLEANING STARTS HERE
    NNF = vc_init_nnf(videoFlow, holeMask, opt);
    
    % Initialize the patch weights
    [NNF.wPatchS, NNF.wVideoSum] = ...
        vc_prep_weight_patch(distMap, NNF.uvPix.sub, iLvl, NNF.uvTrgRefPos, NNF.trgPatchInd, opt);
    
    % Combine spatial and temporal weights: [spPatchSize] x [nFrame] x 1 x [numUvPix]
    NNF.wPatchST = vc_combine_weight_st(NNF.wPatchS, opt.wPatchT, opt);
else
    % BUG: Upsampling
    % Initialize the NNF upsampling of NNF from previous level
    NNF = vc_upsample_flow(videoFlow, holeMask, NNF, opt);
    
    % Initialize the patch weights
    [NNF.wPatchS, NNF.wVideoSum] = ...
        vc_prep_weight_patch(distMap, NNF.uvPix.sub, iLvl, NNF.uvTrgRefPos, NNF.trgPatchInd, opt);
    
    % Combine spatial and temporal weights: [spPatchSize] x [nFrame] x [numUvPix]
    NNF.wPatchST = vc_combine_weight_st(NNF.wPatchS, opt.wPatchT, opt);
    
    % Voting to synthesize the video at the upsampled level
    NNF.updateInd = true(NNF.uvPix.numUvPix, 1);
    videoFlow = vc_voting_update_flow(videoFlow, NNF, holeMask, opt);
end

end