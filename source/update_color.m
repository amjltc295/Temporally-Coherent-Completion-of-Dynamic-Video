function I = update_color(Z, R1, R2, alpha)

%function I = update_color(Z, R, alpha)
% Z: spatial voting
% R1: forward temporal neighbor 
% R2: backward temporal neighbor 
% I: updated color
%    argmin ||I - Z||_2^2 + alpha*\phi(||I - R1||_2^2) + + alpha*\phi(||I - R2||_2^2)

numIter = 5;
eps     = 1e-3;

v1 = sum(R1, 2) == 0;
v2 = sum(R2, 2) == 0;

I_k = Z;
for k = 1:numIter
    dZ  = Z - I_k;
    dR1 = R1 - I_k;
    dR2 = R2 - I_k;

    % Compute the weights
    w1 = alpha*0.5./sqrt(dR1.^2 + eps.^2);
    w2 = alpha*0.5./sqrt(dR2.^2 + eps.^2);

    % Put invalid flow neighbor to zeros
    w1(v1, :) = 0;
    w2(v2, :) = 0;
    
    % Weighted average
    dI  = (dZ + dR1.*w1 + dR2.*w2)./(1 + w1 + w2); 
    % TEST
%     dI  = (0 + dR1.*w1 + dR2.*w2)./(w1 + w2); 

    % Update the solution
    I_k = I_k + dI;
end

I = I_k;

end