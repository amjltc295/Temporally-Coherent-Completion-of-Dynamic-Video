% vc_vis_holemask_batch

videoDir = dir(fullfile('dataset', 'video', '*.avi'));
numVideo = length(videoDir);

for i = 1: numVideo
    try
        vc_vis_holemask(videoDir(i).name);
    catch
        disp(['Cannot visualize video ', videoDir(i).name]);
    end
end