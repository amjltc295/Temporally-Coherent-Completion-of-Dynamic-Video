function syn_texture(textureName)

texturePath = 'dataset\SynTexture';
videoResPath = fullfile(texturePath, 'video');
holePath = fullfile(texturePath, 'hole');

textureName = '7';

%%
img = imread(fullfile(texturePath, [textureName, '.png']));
[imgH, imgW, nCh] = size(img);

% img = im2double(img);
% figure(1); imshow(img);

%% Constant motion
videoName = fullfile(videoResPath, [textureName, '_trans.avi']);
wObj = VideoWriter(videoName);
open(wObj);

Nsize = imgW;
outputView = imref2d([Nsize, Nsize]);
N = 30;

vx = linspace(-N/2,N/2,N);
for i = 1:N
    tform = affine2d([1 0 0; 0 1 0; vx(i) 0 1]);
    imgCur = imwarp(img, tform, 'cubic', 'OutputView', outputView);
    
    writeVideo(wObj, imgCur);
end
close(wObj);

%% Rotational motion
videoName = fullfile(videoResPath, [textureName, '_rot.avi']);
wObj = VideoWriter(videoName);
open(wObj);

N = 30;
theta = linspace(0, pi/2, N);
for i = 1:N
    t = theta(i);
    T1 = eye(3); T1(1:2,3) = -imgW/2;
    R = [cos(t) -sin(t) 0; sin(t) cos(t) 0; 0 0 1];
    T2 = eye(3); T2(1:2,3) = imgW/2;
    A = T2*R*T1;
    tform = affine2d(A');
    imgCur = imwarp(img, tform, 'cubic', 'OutputView', outputView);
    writeVideo(wObj, imgCur);
end
close(wObj);

%% Create hole mask

holeImg = zeros(imgH, imgW);
imgC1 = round(imgH/4);
imgC2 = round(imgH*3/4);

wid = 5;
holeImg(:,imgC1-wid:imgC1+wid) = 1;
holeImg(:,imgC2-wid:imgC2+wid) = 1;

holeMaskTransName = [textureName, '_trans_hole.png'];
holeMaskRotName = [textureName, '_rot_hole.png'];
imwrite(holeImg, fullfile(holePath, holeMaskTransName));
imwrite(holeImg, fullfile(holePath, holeMaskRotName));

end 