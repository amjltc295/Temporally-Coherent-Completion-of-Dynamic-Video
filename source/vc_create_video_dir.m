function vc_create_video_dir(videoName, t)

% === Create result path ===
if(~exist('result', 'dir'))
    mkdir('result')
end

dateStr = [num2str(t.Year), '-', num2str(t.Month, '%02d'), '-', num2str(t.Day, '%02d'),' '];
videoName = [dateStr, videoName];

resPath = 'result/completion_ours';
if(~exist(fullfile(resPath, videoName), 'dir'))
    mkdir(fullfile(resPath, videoName))
end

flowResPath = fullfile(resPath, videoName, 'flow');
if(~exist(flowResPath, 'dir'))
    mkdir(flowResPath);
end

colorResPath = fullfile(resPath, videoName, 'color');
if(~exist(colorResPath, 'dir'))
    mkdir(colorResPath);
end

iterResPath = fullfile(resPath, videoName, 'iter');
if(~exist(iterResPath, 'dir'))
    mkdir(iterResPath);
end

visResPath = fullfile(resPath, videoName, 'visual');
if(~exist(visResPath, 'dir'))
    mkdir(visResPath);
end

% === Flow ===
if(~exist('cache', 'dir'))
    mkdir('cache');
end

flowDataPath = 'cache/flowData';
if(~exist(flowDataPath, 'dir'))
    mkdir(flowDataPath);
end

end