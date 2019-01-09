%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Flexible probabilities according to a kernel
% Conditioning according to the VIX: vix_limit variable 
% Kernel damping as in Meucci 2008
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y=vix_limit;
h2=cov(diff(vix_prices2));
p_kernel=mvnpdf(vix_prices2,y,h2);
p_kernel=p_kernel/sum(p_kernel);

figure
subplot(2,1,1)
    plot(vix_dates2,vix)
    hold on
    plot(vix_dates2,repmat(vix_limit,T,1))
    title('Conditioning variable')
    legend('VIX index',sprintf('VIX=%d',vix_limit))
    hold off
subplot(2,1,2)
    plot(vix_dates2,p_kernel)
    title('Flexible probabilities smooth kernel')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% partial information prox. kernel damping
% instead of inflation (as in original example) we condition
% according to the VIX index
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
y=vix_limit;
h2=NaN; % set h2=NaN for no conditioning on second moments
h2=cov(1*diff(vix));
p_least_info_kernel=LeastInfoKernel(vix,y,h2);

figure
subplot(2,1,1)
    plot(vix_dates2,vix)
    hold on
    plot(vix_dates2,repmat(vix_limit,T,1))
    title('Conditioning variable')
    legend('VIX index',sprintf('VIX=%d',vix_limit))
    hold off
subplot(2,1,2)
    plot(vix_dates2,p_least_info_kernel)
    title('Least information kernel flexible')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% So called crisp market conditioning: probability of a scenario
% is either fixed or zero depending on the conditioning variable
% which is in this case the VIX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p_crisp=(vix>vix_limit)/sum((vix>vix_limit));
figure
subplot(2,1,1)
    plot(vix_dates2,vix)
    hold on
    plot(vix_dates2,repmat(vix_limit,T,1))
    title('Conditioning variable')
    legend('VIX index',sprintf('VIX=%d',vix_limit))
    hold off
subplot(2,1,2)
    plot(vix_dates2,p_crisp)
    title('Crisp conditioning (either 1 or 0)')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% Next historical PnL scenarios for real S&P500 and
% equally weighted portfolio
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[sortedPnL,sortInd]=sort(port_pnl);

cdf_crisp=cumsum(p_crisp(sortInd));
cdf_lik=cumsum(p_least_info_kernel(sortInd));
cdf_kernel=cumsum(p_kernel(sortInd));
p_normal=ones(size(p_kernel))/length(p_kernel);
cdf_normal=cumsum(p_normal(sortInd));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some basic statistics of historical scenarios
% mean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_crisp=port_pnl'*p_crisp(2:end);
mean_lik=port_pnl'*p_least_info_kernel(2:end);
mean_kernel=port_pnl'*p_kernel(2:end);
mean_normal=port_pnl'*p_normal(2:end);
means=[mean_crisp mean_lik mean_kernel mean_normal];

%volatility
vol_crisp=vol_flex_prob(port_pnl,p_crisp(2:end));
vol_lik=vol_flex_prob(port_pnl,p_least_info_kernel(2:end));
vol_kernel=vol_flex_prob(port_pnl,p_kernel(2:end));
vol_norm=vol_flex_prob(port_pnl,p_normal(2:end));
vols=[vol_crisp vol_lik vol_kernel vol_norm];

%cvar
cvar_crisp=cvar_function(1-0.95,cdf_crisp,sortedPnL,p_crisp(sortInd));
cvar_lik=cvar_function(1-0.95,cdf_lik,sortedPnL,p_least_info_kernel(sortInd));
cvar_kernel=cvar_function(1-0.95,cdf_kernel,sortedPnL,p_kernel(sortInd));
cvar_normal=cvar_function(1-0.95,cdf_normal,sortedPnL,p_normal(sortInd));
cvars=[cvar_crisp cvar_lik cvar_kernel cvar_normal];

cols={'Means','Vols','CVaRs'};
rows={'Crisp','Least info kernel','Smooth kernel','Normal'}';
disp(cols)
disp([means' vols' cvars'])
disp(rows)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% From previous statistics we can observe that all historical scenarios
% with flexible probabilities have worse performance than in unconditioned
% historical scenarios with equal probabilities (called "normal" in this
% context).
% This is expected behaviour, since in the conditioning we gave more weight
% to the extreme events when our panic indicator VIX is peaking above
% defined treshold (vix_limit).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now we plot the CDFs resulting of different conditioning
figure
    plot(sortedPnL,cdf_crisp,'-.')
    hold on
    plot(sortedPnL,cdf_lik,'-k')
    plot(sortedPnL,cdf_kernel,'-r')
    plot(sortedPnL,cdf_normal,'-')

    ylim([0 1])
    xlim([85 115])
    xlabel('PnL of equally weighted portfolio')
    ylabel('Probability')
    title('CDFs of different methods to generate flexible probability scenarios')
    grid on
    plot(means(1:3),[0 0 0],'r*')
    plot(cvars(1:3),[0 0 0],'bo')
    plot([means(4) means(4)],[0 1],'--r')
    plot([cvars(4) cvars(4)],[0 1],'--k')
    legend('Crisp conditioning','Least information kernel','Smooth kernel','No conditioning (historical)','Means, conditioned','CVaRs, conditioned','Mean, historical','CVaR, historical','location','southeast')    
    hold off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%