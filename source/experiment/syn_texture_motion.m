function syn_texture_motion(motionType)

% SYN_TEXTURE_MOTION
%
% Synthesize moving textures
%
% Input:
%   - motionType: 'rotation', 'scale'
%

% motionType = 'rotation';
% motionType = 'scale';
% motionType = 'translation';

% motionTypeList = {'scale', 'translation', 'rotation'};
motionTypeList = {'scale', 'rotation', 'translation'};

% =========================================================================
% Set up paths
% =========================================================================
% Input texture images and result path
texturePath = 'texture';

textureImgPath   = fullfile(texturePath, 'image');
videoResPath = fullfile('dataset', 'video');
flowResPath  = fullfile('cache', 'flowData');

% Texture images
imgDir = dir(fullfile(textureImgPath, '*.jpg'));
numImg = length(imgDir);

% Parameter set up
numFrame = 60;      % Number of frames

opt.transStep   = 1;
opt.scalingStep = 0.005;
opt.angleStep   = 2*pi/numFrame;

% =========================================================================
% Synthesize flow and color of moving textures
% =========================================================================

for indMotionType = 1: length(motionTypeList)
    
    motionType = motionTypeList{indMotionType};
    for indImg = 1: numImg
        
        videoName = [imgDir(indImg).name(1:end-4), '_', motionType, '.avi'];
        if(~exist(fullfile(videoResPath, videoName), 'file'))
            % =====================================================================
            % Load a texture image
            % =====================================================================
            imgName = fullfile(textureImgPath, imgDir(indImg).name);
            img = imread(imgName);
            
            % Get image size
            [imgH, imgW, nCh] = size(img);
            imgSize = min(imgH, imgW) - 1;
            imgSize = floor(2.^(nextpow2(imgSize) -1));
            
            img = img(1:imgSize, 1:imgSize,:);    % Cropped image
            img = im2single(img);                 % Convert to single type
            
            % Anti-alising
            if(indImg == 6) 
                sigma = 2;
            else
                sigma = 1.8;
            end
            h = fspecial('gaussian', 9, sigma);
            img = imfilter(img, h, 'conv', 'same');
            
            % Upsample the image to avoid alising
            scaleD   = 0.5;
            img = imresize(img, 1/scaleD, 'bicubic');
            imgSize = (1/scaleD)*imgSize;
            
            % =====================================================================
            % Compute the image grid positions
            % =====================================================================
            xCenter  = imgSize/2;
            yCenter  = imgSize/2;
            
            % Get grid of x,y positions
            pos = getGridPos(imgSize);
            
            % Initialize the synthesized video
            videoSyn = zeros(imgSize, imgSize, 3, numFrame, 'single');
            
            videoSyn(:,:,:,1) = img; % imresize(img, scaleD, 'bicubic');
            
            % =====================================================================
            % Synthesize video by resampling
            % =====================================================================
            for j = 2: numFrame
                direction = 1;
                [Dx, Dy] = getResamplePosVec(pos, opt, motionType, j-1, direction);
                Dx = reshape(Dx, [imgSize, imgSize]);
                Dy = reshape(Dy, [imgSize, imgSize]);
                
                % Synthesize moving textures
                X_ = single(Dx + xCenter);
                Y_ = single(Dy + yCenter);
                
                % Bilinear interpolation
                videoSyn(:,:,:,j) = vgg_interp2(img, X_, Y_, 'linear', 0);
                disp(['Processing texture ', imgName(1:end-4),' : ', num2str(j),'/', num2str(numFrame)]);
            end
            
            % =====================================================================
            % Synthesize optical flow
            % =====================================================================
            direction = -1;
            imgSizeD = imgSize/2;
            xCenterD = imgSizeD/2;
            yCenterD = imgSizeD/2;
            
            posD = getGridPos(imgSizeD);
            [Dx, Dy] = getResamplePosVec(posD, opt, motionType, 1, direction);
            Dx = reshape(Dx, [imgSizeD, imgSizeD]) + xCenterD;
            Dy = reshape(Dy, [imgSizeD, imgSizeD]) + yCenterD;
            
            [X, Y] = meshgrid(1:imgSizeD, 1:imgSizeD);
            if(strcmp(motionType, 'rotation'))
                Dx = -(X - Dx);
                Dy = -(Y - Dy);
            else
                Dx = (X - Dx);
                Dy = (Y - Dy);
                if(strcmp(motionType, 'translation'))
                    Dx = scaleD*Dx;
                    Dy = scaleD*Dy;
                end
            end
            videoFlowF = single(cat(3, Dx, Dy));
            videoFlowF = videoFlowF(:,:,:,ones(numFrame, 1));
            videoFlowB = -videoFlowF;
            
            % =====================================================================
            % Downsampling
            videoSyn = imresize(videoSyn, scaleD, 'bilinear');
            
            % Cropping
            radC = 150;
            c = floor(scaleD*imgSize/2);
            pRange = c-radC:c+radC;
            videoSyn = videoSyn(pRange, pRange, :, :);
            videoFlowF = videoFlowF(pRange, pRange, :, :);
            videoFlowB = videoFlowB(pRange, pRange, :, :);
            
            videoSyn = vc_clamp(videoSyn, 0, 1);
            
            % =================================================================
            % =============== TEST FLOW with warping ===============
            % =================================================================
            if(0)
                [X, Y] = meshgrid(1: 2*radC+1, 1: 2*radC+1);
                indF = 5;
                flow = videoFlowF(:,:,:,indF);
                X_ = X + flow(:,:,1);
                Y_ = Y + flow(:,:,2);
                imgWarp = vgg_interp2(videoSyn(:,:,:,indF+1), X_, Y_, 'linear', 0);
                imgCurr = videoSyn(:,:,:,indF);
                figure(2); imshow(imgCurr);
                figure(3); imshow(imgWarp);
                A = imgCurr - imgWarp;
                figure(4); imshow(A/256 + 0.5);
            end
            
            
            % Save video
            wVidObj = VideoWriter(fullfile(videoResPath, videoName), 'Uncompressed AVI');
            open(wVidObj);
            for j = 1:numFrame
                imgCur = videoSyn(:,:,:,j);
                writeVideo(wVidObj, imgCur);
            end
            close(wVidObj);
            
            flowName = [videoName(1:end-4), '_flow.mat'];
            save(fullfile(flowResPath, flowName), 'videoFlowF', 'videoFlowB');
            
            disp(['Processing texture ', num2str(indImg), '/', num2str(numImg)]);
        end
    end
end
end

function pos = getGridPos(imgSize)

xCenter = imgSize/2;
yCenter = imgSize/2;

[X, Y] = meshgrid(1:imgSize, 1:imgSize);
X = single(X);
Y = single(Y);

% Centered positions
Xc = X - (xCenter);
Yc = Y - (yCenter);
pos = cat(2, Xc(:), Yc(:));

end

function [Dx, Dy] = getResamplePosVec(pos, opt, motionType, j, direction)
% Get resampling positions
if(strcmp(motionType, 'rotation'))   % Rotational motion
    theta = -j*direction*opt.angleStep;
    cosT = cos(theta);
    sinT = sin(theta);
    
    Dx = pos*[cosT; -sinT];
    Dy = pos*[sinT;  cosT];
elseif(strcmp(motionType, 'scale'))   % Scaling motion
    Dx = pos(:,1)*(1 + opt.scalingStep).^(j);
    Dy = pos(:,2)*(1 + opt.scalingStep).^(j);
elseif(strcmp(motionType, 'translation'))   % Translation motion
    Dx = pos(:,1) + (j)*opt.transStep;
    Dy = pos(:,2); % + 0*(j)*opt.transStep;
else
    error('The motion type must be either rotation or scale.');
end


end