% Get a list of all files and folders in this folder.
files = dir('./dataset/test_20181109_videos');
% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];
video_names = files(~dirFlags);

for i = 12 : length(video_names)
    video_name = video_names(i).name;
    video_name = split(video_name, '.');
    vc_complete(video_name{1})
end
