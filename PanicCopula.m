
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finally we try some panic copulas using the correlations
% defined by "crisp" conditioning, meaning that the panic correlation
% is calculated from the observations from periods when VIX index
% is above the conditioning treshold, and calm correlations when it is
% below.
%
% we have used similar methods as in S_PanicCopula in
% http://www.symmys.com/node/335
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% panic correlation = panic_corr
% calm correlation = calm_corr

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate panic distribution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numScens=10000;
p=ones(numScens,1)/numScens;

%changind this variable b changes how bad scenarios we treat with panic
b=0.99; 
s2=blkdiag(calm_corr,panic_corr);
hist_means=mean(stock_log);
Z = MvnRnd([hist_means';hist_means'],s2,numScens);
X_c = Z(:,1:n);
X_p = Z(:,(n+1):end);
D = (normcdf(X_p)<b);

X=(1-D).*X_c+D.*X_p;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% perturb probabilities via Fully Flexible Views
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Aeq = ones(1,numScens);  % constrain probabilities to sum to one...
beq=1;
Aeq = [Aeq; X'];  % ...constrain the first moments...
beq=[beq; zeros(n,1)];
p_ = EntropyProg(p,[],[],Aeq ,beq); % ...compute posterior probabilities

[xdd,udd,U]=CMAseparation(X,p_);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% merge panic copula with normal marginals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y=[];
u=[];

%historical vols
for nn=1:n
    % Calculate the vol from invariants
    sig(nn)=std(stock_log(:,nn));
    mean_hist(nn)=mean(stock_log(:,nn));
    yn = linspace(-4*sig(nn),4*sig(nn),100)';
    un=normcdf(yn,mean_hist(nn),sig(nn));
    
    y=[y yn];
    u=[u un];
end
Y=CMAcombination(y,u,U);
% Invariants are log-returns, that are normally distributed.
% Here we convert to linear returns to do the portfolio aggregation.
Y_lin=exp(Y)-1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute portfolio risk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
w=ones(n,1)/n; % portfolio weights
% equally weighted portfolios
% Portfolio aggregation
R_w=Y_lin*w;

[sortedRet, sortedInd2]=sort(R_w);
[sortedRetHist, sortedIndHist]=sort(port_ret);

figure
    plot(sortedRet,cumsum(p_(sortedInd2)),'b-')
    hold on
    plot(sortedRetHist,cumsum(ones(size(sortedRetHist,1))/size(sortedRetHist,1)),'r-')
    legend('Panic copula','Historical distribution','location','southeast')
    ylim([0 1])
    grid on
    title('CDFs of scenarios from panic copula and history')
    xlabel('Return')
    ylabel('Probability')
    hold off
% Historical distribution seems to be somewhat more fat tailed than our
% Panic copula
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot both: historical and panic copula scenarios
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
top_btm2=[min(sortedRetHist) max(sortedRetHist)];
figure
[n2,D2]=pHist(R_w,p_,round(10*log(T))  );
subplot(2,1,1)
    h=bar(D2,n2,1);
    grid on
    xlim(top_btm2)
    title('Panic copula using historical correlations')
[n3,D3]=pHist(port_ret,p_normal,round(10*log(T))  );
subplot(2,1,2)
    h=bar(D3,n3,1);
    xlim(top_btm2)
    grid on
    title('Pure historical return scenarios')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Basic statistics of panic copula and historical scenarios
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_pc=sum(R_w.*p_);
mean_hist=sum(port_ret.*p_normal(2:end));

vol_pc=vol_flex_prob(R_w,p_);
vol_hist=vol_flex_prob(port_ret,p_normal(2:end));

[sortR,sortIndC]=sort(R_w);
[sortHist,sortIndH]=sort(port_ret);

cvar_pc=cvar_function(1-0.95,cumsum(p_(sortIndC)),sortR,p_(sortIndC));
cvar_hist=cvar_function(1-0.95,cumsum(p_normal(sortIndH)),sortHist,p_normal(sortIndH));

cols2={'mean','vol','cvar'};
disp(cols2)
disp([mean_pc,vol_pc,cvar_pc;mean_hist,vol_hist,cvar_hist])
disp({'Panic copula','Historical scenarios'}')

% As expected, the historical scenarios are more negative when measured
% by these basic statistics.
% This is probably due to the fact that the panic and calm correlations
% are actually quite close to one another, so the difference between
% these market environments is not huge.
% Moreover, in the artificial example provided by Meucci et co the
% panic correlation is set to very extreme: 0.99, which is much higher than
% the correlations we observe in panic_corr.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%