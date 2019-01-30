function vc_get_mask_from_rectangle(videoName)

videoName = 'VSB_snowboarding';

vidObj = VideoReader(fullfile('dataset', 'video', [videoName, '.avi']));
videoFrame = read(vidObj, 1);
[imgH, imgW, nCh] = size(videoFrame);

numVideoFrame = vidObj.NumberOfFrames;
holeMask = false(imgH, imgW, numVideoFrame);

holeMaskName = fullfile('dataset', 'hole', [videoName, '_hole.avi']);
if(exist(holeMaskName, 'file'))
    holeVidObj = VideoReader(holeMaskName);
end

figure(1); imshow(videoFrame);
h = impoly;
poly = wait(h);

for i = 1:numVideoFrame
    videoFrame = read(vidObj, i);
    figure(1); imshow(videoFrame);
    
    h = impoly(gca, poly);
    
    % allow dragable rectangle
    addNewPositionCallback(h,@(p) title(mat2str(p,3)));
    fcn = makeConstrainToRectFcn('impoly',get(gca,'XLim'),...
        get(gca,'YLim'));
    setPositionConstraintFcn(h,fcn);
    
    % Save result
    poly = wait(h);
    holeMask(:,:,i) = poly2mask(poly(:,1),poly(:,2),imgH,imgW);
    if(exist(holeMaskName, 'file'))
        mask = read(holeVidObj, i);
        mask = mask == 255;
        holeMask(:,:,i) = holeMask(:,:,i) | mask;
    end
end

if(exist(holeMaskName, 'file'))
    release(holeVidObj);
end

% Visualization
holeMask = im2double(holeMask);
wVidObj = VideoWriter(holeMaskName, 'Grayscale AVI');
open(wVidObj);
for i = 1:numVideoFrame
    writeVideo(wVidObj, holeMask(:,:,i));
    disp(['Processing frame ', num2str(i)]);
end
close(wVidObj);

end