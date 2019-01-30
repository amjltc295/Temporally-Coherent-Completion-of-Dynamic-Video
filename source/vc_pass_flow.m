function  [videoFlow, NNF] = vc_pass_flow(videoFlow, holeMask, NNF, numIterLvl, iLvl, opt, lockFlag)

%%

for iter = 1 : numIterLvl
    % === Compute the patch matching cost at the current level ===
    % Prepare target and source patches
    trgPatch = vc_prep_flow_patch(videoFlow, NNF.uvPix.sub, NNF.uvTrgRefPos);
    srcPatch = vc_prep_flow_patch(videoFlow, NNF.uvT.data,  NNF.uvSrcRefPos);
    
    % Apply patch transformation to the source patch
    % Compute patch matching cost
    [NNF.uvCost, NNF.uvFlowTformT.data] = vc_patch_cost_flow(trgPatch, srcPatch, videoFlow, ...
        NNF.uvFlowTformA.data, NNF.uvPix.sub, NNF.wPatchST, NNF.uvSrcRefPos, opt);
    
    % === Update the NNF using the PatchMatch algorithm ===
    [NNF, nUpdate] = vc_update_NNF_flow(trgPatch, videoFlow, NNF, opt);
    
    % === Update the image ===
    if(~lockFlag)
        videoFlow = vc_voting_update_flow(videoFlow, NNF, holeMask, opt);
        
        % Visualize
        img = flowToColor(videoFlow(:,:,:,4,1));
        imgResName = fullfile(opt.resPath, opt.videoName, ['flow_res_lvl_',num2str(iLvl, '%02d'),'_iter_' num2str(iter, '%04d'), '.png']);
        imwrite(img, imgResName);
    end
    
    % Display the current errors
    wPatchSum = squeeze(sum(sum(NNF.wPatchST, 1), 2));
    uvCost = NNF.uvCost./wPatchSum;
    avgPatchCost = mean(uvCost, 1);
    
    % Report current progress
    fprintf('    %3d\t%12d\t%12d\t%14f\n', iter, nUpdate(1), nUpdate(2), avgPatchCost);
end


end