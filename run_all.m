fprintf('Start Time:')
start_time = clock
% Get a list of all files and folders in this folder.
files = dir('./dataset/video');
% files = dir('./dataset/test_20181109_videos');
% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir];
video_names = files(~dirFlags);
error_num = 0;

for i = 1 : length(video_names)
    try
        video_time = clock
        video_name = video_names(i).name;
        video_name = split(video_name, '.');
        vc_complete(video_name{1})
        fprintf('Video Time:')
        clock - video_time
    catch e %e is an MException struct
        fprintf(1,'The identifier was:\n%s',e.identifier);
        fprintf(1,'There was an error! The message was:\n%s',e.message);
        error_num = error_num + 1;
    end
end

fprintf('Total Time:')
clock - start_time
fprintf('Error num:')
error_num
