function data = vc_video_ind2data(V, ind)

% V: H x W x nCh x nFrame
% p:   N x 1
% data: N x nCh

nCh = size(V, 3);
N = size(ind, 1);
data = zeros(N, nCh, 'single');

% % [I, J, K] = ind2sub()
% 
% sub



for iCh = 1: nCh
    Vch = V(:,:,iCh,:);
    data(:,iCh) = Vch(ind);
end

end