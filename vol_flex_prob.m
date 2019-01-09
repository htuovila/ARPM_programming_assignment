function [ vol ] = vol_flex_prob( pnl,p )
% Calculate the volatility of a flexible probability
% distribution

    mu=sum(pnl.*p);
    
    vol=sqrt(sum(((pnl-mu).^2).*p));

end

