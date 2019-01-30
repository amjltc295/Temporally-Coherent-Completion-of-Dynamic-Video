function vc_vis_flow_forward_backward(videoData, videoFlow, videoOccMask, opt)

[imgH, imgW, nCh, nFrame, nFlow] = size(videoFlow);

videoData = im2double(videoData);
videoFlow = double(videoFlow);

[X, Y] = meshgrid(1:imgW, 1:imgH);

if(isempty(videoOccMask))
   videoOccMask = zeros(imgH, imgW, nFrame); 
end

% =========================================================================
% Test forward flow
% =========================================================================
flowWarpPath = fullfile(opt.visResPath, 'warp');
if(~exist(flowWarpPath, 'dir'))
    mkdir(flowWarpPath);
end

if(opt.useFwFlow)
    flowWarpCurPath = fullfile(flowWarpPath, 'forward');
    if(~exist(flowWarpCurPath, 'dir'))
        mkdir(flowWarpCurPath);
    end

    ffCh = 1;
    for i = 1:nFrame-ffCh
        A = videoFlow(:,:,:,i, ffCh);
        vx = A(:,:,1);
        vy = A(:,:,2);
        
        img1 = videoData(:,:,:, i);
        img2 = videoData(:,:,:, i+1);
        img2w = zeros(size(img2));
        for iCh = 1: 3
            img2w(:,:,iCh) = interp2(img2(:,:,iCh), X + vx, Y + vy);
        end
        occMask = im2double(videoOccMask(:,:,i));
        img2w(:,:,1) = img2w(:,:,1) + 0.5*occMask;
        
        imgName1 = [opt.videoName, '_', num2str(i, '%03d'), '_Curr.png'];
        imgName2 = [opt.videoName, '_', num2str(i, '%03d'), '_Warp.png'];
        
        imwrite(img1,  fullfile(flowWarpCurPath,  imgName1));
        imwrite(img2w, fullfile(flowWarpCurPath,  imgName2));
    end
end
% =========================================================================
% Test backward flow
% =========================================================================

% for ffCh = 1:2
if(opt.useBwFlow)
    flowWarpCurPath = fullfile(flowWarpPath, 'backward');
    if(~exist(flowWarpCurPath, 'dir'))
        mkdir(flowWarpCurPath);
    end

    ffCh = 2;
    for i = nFrame:-1:ffCh
        A = videoFlow(:,:,:,i, 2);
        vx = A(:,:,1);
        vy = A(:,:,2);
        img1 = videoData(:,:,:, i);
        img2 = videoData(:,:,:, i-1);
        img2w = zeros(size(img2));
        for iCh = 1: 3
            img2w(:,:,iCh) = interp2(img2(:,:,iCh), X + vx, Y + vy);
        end

        imgName1 = [opt.videoName, '_', num2str(i, '%03d'), '_Curr.png'];
        imgName2 = [opt.videoName, '_', num2str(i, '%03d'), '_Warp.png'];
        
        imwrite(img1,  fullfile(flowWarpCurPath,  imgName1));
        imwrite(img2w, fullfile(flowWarpCurPath,  imgName2));
     end
end

end