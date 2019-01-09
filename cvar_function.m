function [ cvar ] = cvar_function(confidence,cdf,pnl,probs)
% Calculate the CVaR of the flexible probability
    max_ind=max(find(cdf<confidence));
    
    cvar=sum(pnl(1:max_ind).*(probs(1:max_ind)/sum(probs(1:max_ind))));
    
end

