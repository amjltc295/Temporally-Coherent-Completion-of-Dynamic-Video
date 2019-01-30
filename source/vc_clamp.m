function y = vc_clamp(x, lb, ub)

% VC_CLAMP: clamping values to [lb, ub]
% 
% Input: 
%  - x:  input array
%  - lb: lower bound value
%  - ub: upper bound value
% Output:
%  - y : clamped results

y = min(x, ub);
y = max(y, lb);