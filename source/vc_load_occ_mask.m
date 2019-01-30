function videoOccMask = vc_load_occ_mask(videoName, imgSize)

% Load occlusion mask
occMaskPath = fullfile('dataset', 'occlusions', videoName(5:end));

imgDir = dir(fullfile(occMaskPath, '*.png'));

nFrame = length(imgDir);

videoOccMask = false(imgSize(1), imgSize(2), nFrame);

for i = 1: nFrame
    img = imread(fullfile(occMaskPath, ['frame_',num2str(i,'%04d'), '.png']));
    videoOccMask(:,:,i) = img == 255;
end

% Dilate the mask to avoid motion blur
% videoOccMask = imdilate(videoOccMask, strel('square', 3));
videoOccMask = single(videoOccMask);

end