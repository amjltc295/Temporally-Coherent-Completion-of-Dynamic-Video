function uvValidInd = vc_check_valid_uv(uvSub, validMask)

% tic;
% % Check if uvSub are out of bounds
% numUvPix = size(uvSub, 1);
% uvSub    = round(uvSub);
% videoSize = [size(validMask, 2), size(validMask,1), size(validMask,3)];
% uvValidLimitInd = vc_check_index_limit(uvSub, videoSize);
% 
% % Check if the uvSub are valid
% uvSub = uvSub(uvValidLimitInd,:);
% uvInd = sub2ind(size(validMask), uvSub(:,2), uvSub(:,1), uvSub(:,3));
% 
% uvValidInd  = false(numUvPix, 1);
% uvValidInd(uvValidLimitInd, :) = validMask(uvInd);
% toc

interpolationKernel = 'linear';

uvValidInd = vc_interp3(validMask, uvSub, interpolationKernel);
uvValidInd = uvValidInd > 0.99;

end