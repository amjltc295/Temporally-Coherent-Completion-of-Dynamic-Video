function videoData = vc_init_completion(videoData, holeMask, dim)
% VC_INIT_COMPLETION: Video completion using diffusion-based inpainting
% Input:
%   - video:    color or flow data
%   - holeMask: hole
%   - dim:      use 2D or 3D inpainting
%
% Output:
%   - videoRes: inpainted color or flow video
% =========================================================================

holeMask = logical(holeMask);

% if(numDims == 4)     % Video data
if(dim==2)
    videoData = init_completion_2D(videoData, holeMask);
elseif(dim==3)
    videoData = init_completion_3D(videoData, holeMask);
else
    error('The dimension could only be 2 or 3');
end

end


function videoData = init_completion_2D(videoData, holeMask)

% Inpaint the video using 2D diffusion-based inpainting

nCh    = size(videoData, 3);
nFrame = size(videoData, 4);

fprintf('Initial video inpainting: \n');
tic;
for iFrame = 1:nFrame
    for iCh = 1: nCh
        videoCh = squeeze(videoData(:,:,iCh,iFrame));
        videoData(:,:,iCh,iFrame) = regionfill(videoCh, holeMask(:,:,iFrame));
    end
end
t = toc;
fprintf('%30sdone in %.03f seconds \n', '',t);

end

function videoData = init_completion_3D(videoData, holeMask)
% Inpaint the video using 3D diffusion-based inpainting

nCh = size(videoData, 3);

fprintf('Initial video inpainting: \n');
tic;
% Inpaint the video volumn using diffusion-based inpainting
for iCh = 1: nCh
    videoCh = squeeze(videoData(:,:,iCh,:));
    videoCh(holeMask) = nan;
    videoData(:,:,iCh, :) = inpaintn(videoCh);
end
t = toc;
fprintf('%30sdone in %.03f seconds \n', '',t);

end