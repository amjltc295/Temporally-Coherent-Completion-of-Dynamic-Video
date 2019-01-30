function save_mask(videoName, holeMask)

wVidObj  = VideoWriter([videoName, '_hole.avi'], 'Grayscale AVI');
open(wVidObj);

for i = 1: size(holeMask, 3)
    writeVideo(wVidObj, holeMask(:,:,i));
end

close(wVidObj);
end