function [videoColor, NNF] = ...
    vc_pass(videoColor, videoFlow, flowNN, NNF, opt, lockFlag)
% VC_PASS: Patch-based optimization for synthesizing video and flow
% Input:
%   - videoData: video data - [imgH] x [imgW] x [3] x [nFrame]  (color only)
%                             [imgH] x [imgW] x [5] x [nFrame]  (color + x-, y- gradient)
%   - videoFlow: flow data  - [imgH] x [imgW] x [2] x [nFrame] x [2]
%   - occMask:   occlusion mask
%   - NNF:       current nearest neighbor field
%   - opt:       algorithm parameters
%   - lockFlag:  lockFlag = 1 => do not update video, 0 otherwise
%
% Output:
%   - videoData: updated colors
%   - videoFlow: updated flow
%   - NNF:       updated nearest neighbor field

initLvlFlag = opt.iLvl == opt.numPyrLvl;

if(~initLvlFlag)
    % Connected pixels: with at least one flow neighbor
    connectedPixInd = (flowNN(:, 3, 1) ~= 0) | (flowNN(:, 3, 2) ~= 0);
    mask = false(NNF.imgH, NNF.imgW, NNF.nFrame);
    mask(NNF.holePix.ind) = ~connectedPixInd;
    isolatedTrgPixInd     = mask(NNF.trgPix.ind);
else
    connectedPixInd    = [];
    isolatedTrgPixInd  = [];
end

for iter = 1 : opt.numIterLvl
    opt.iter = iter;
    
    % =====================================================================
    % Compute the patch matching cost at the current level
    % =====================================================================
    % Prepare target and source patches
    trgPatch = videoColor(NNF.trgPatchInd);
    srcPatch = vc_prep_source_patch(videoColor, NNF.srcPos.data, NNF.srcTfmG.data, ...
        NNF.patchRefPos);
    
    % Compute appearance cost
    NNF.uvCost(:,1) = vc_patch_cost_app(trgPatch, srcPatch, opt.wPatchM);
    % Compute coherence cost
    if(opt.useCoherence)
        uvValidPos = 1:NNF.trgPix.numPix;
        uvCostCoh = vc_patch_cost_coherence(NNF.srcPos.map, NNF.trgPixN, NNF.srcPos.data, ...
            uvValidPos, opt);
        NNF.uvCost(:,2) = uvCostCoh;
    end
    
    % =====================================================================
    % Update the NNF using the spatial-temporal PatchMatch algorithm
    % =====================================================================
    [NNF, nUpdate]= vc_update_NNF(trgPatch, videoColor, videoFlow, NNF, isolatedTrgPixInd, opt);
    
    % Without updating the video
    if(lockFlag)
        continue;
    end
    
    % =====================================================================
    % Update the videoData
    % =====================================================================
    % (1) Spatial color voting
    colorData = vc_voting_color(videoColor, NNF);
%     videoColor(NNF.holePix.indC) = colorData;
    
    if(~initLvlFlag)
        % (2) Fix flow, update color
        interpolationKernel = 'bicubic';
        colorDataFw = vc_interp3(videoColor, flowNN(connectedPixInd, :, 1), interpolationKernel);
        colorDataBw = vc_interp3(videoColor, flowNN(connectedPixInd, :, 2), interpolationKernel);
        colorData   = colorData(connectedPixInd, :);
        
        colorDataN = update_color(colorData, colorDataFw, colorDataBw, opt.alphaT);
        videoColor(NNF.holePix.indC(connectedPixInd,:)) = colorDataN;
    end
    
    % =========================================================================
    % Exporting the results at the current iteration
    % =========================================================================
    % Display the current errors
    avgPatchCost = mean(NNF.uvCost(:,1), 1);
    
    fprintf('    %3d\t%12d\t%12d\t%12d\t%14f\n', iter, ...
        nUpdate.propSpatial, nUpdate.propTemporal, nUpdate.randSearch, avgPatchCost);
end
end

