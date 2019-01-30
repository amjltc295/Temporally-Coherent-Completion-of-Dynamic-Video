function x = vc_clamp_ch(x, lb, ub)

nCh = size(x,2);
for i = 1:nCh
    x(:,i) = vc_clamp(x(:,i), lb(i), ub(i));
end

end