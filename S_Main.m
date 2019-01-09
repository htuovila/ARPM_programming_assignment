%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ARPM Bootcamp practice for  pursuing certificate
% By Henri Tuovila
% henri.tuovila@gmail.com
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The program S_Main uses these files, scripts and functions
% -project_data.mat
% -PanicCopula
% -cvar_function
% -vol_flex_prob
% -FlexibleProbabilities
% -PanicCopula
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% And
% These functions provided by the bootcamp:
% -pHist
% -MvnRnd
% -CMAseparation
% -CMAcombination
% -LeastInfoKernel
% -EntropyProg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; clc; close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load all the data
load('project_data.mat')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cleaning the data
run clean_data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the treshold for the VIX: above this we consider to be a panic
% market environment, below calm
vix_limit=27;
vix=vix_prices2(:,1); %shorter notation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Here we can choose which stocks to show in the plots from n=177 possible
% Stock tickers are saved in the variable stock_names
indices=[1 4];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scatter histogram of the stock returns 
figure
    scatterhist(stock_log(:,indices(1)),stock_log(:,indices(2)));
    xlabel(stock_names(indices(1)))
    ylabel(stock_names(indices(2)))
    grid on
    hold on
 
    % highlight observations above certain VIX treshold    
    above_limit=vix_prices2(1:(end-1),1)>vix_limit;
    plot(stock_log(above_limit,indices(1)),stock_log(above_limit,indices(2)),'r*');
    grid on
    legend('All observations','Indicator above treshold','location','northwest')
    hold off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Visualize the observed VIX values (remove commenting)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
%     hist(vix)
%     hold on
%     plot([vix_limit vix_limit],[0 100],'r')
%     legend('VIX values','Treshold')
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define whether the VIX treshold is breached or not
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
below_limit=logical(1-above_limit);
total_corr=corr(stock_log);
calm_corr=corr(stock_log(below_limit,:));
panic_corr=corr(stock_log(above_limit,:));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Are the correlations actually higher in panic environments?
% We plot the proportion of equity correlations higher in panic compared
% to calm market environment. Surprisingly for some stocks we see
% higher correlations in calm markets than in panic markets, but for
% most the original hypothesis of higher panic correlation holds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n=size(calm_corr,1);  
higher_corr=sum(panic_corr-calm_corr>=0)/n;
figure
    plot(higher_corr,'*')
    title('Proportion of correlations being higher in panic than in calm markets')
    grid on
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
% CMA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p=ones(size(stock_log(:,indices(1))))/length(stock_log(:,indices(1)));
[x,u,U]=CMAseparation(stock_log(:,indices),p);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Scatter histogram of copula
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
    scatterhist(U(:,1),U(:,2));
    xlabel(stock_names(indices(1)))
    ylabel(stock_names(indices(2)))
    grid on
    hold on
    % highlight observations above certain VIX treshold    
    above_limit=vix_prices2(1:(end-1),1)>vix_limit;
    plot(U(above_limit,1),U(above_limit,2),'r*');
    grid on
    legend('All observations','Indicator above treshold','location','northwest')
    hold off
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Historical return scenarios for equally weighted portfolio
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
stock_lin=exp(stock_log)-1;
stock_weights=ones(1,n)/n;
port_ret=stock_lin*stock_weights';
comp_ret=log(port_ret+1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constructing an artificial index of equal weights and immediate
% rebalancing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
port_pnl=(port_ret+1)*100;
sp500_pnl=(exp(sp500_log))*100;
constructed_index=ones(T,1)*100;
for t=2:T
    constructed_index(t)=constructed_index(t-1)*(exp(log(port_ret(t-1)+1)));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Control checks that the equally weighted index
% and S&P have some resemlance so that we have avoided major mistakes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% con_ind_inv=log(constructed_index(2:end)./constructed_index(1:(end-1)));
% corr(con_ind_inv,sp500_log)
% 
% figure
%     scatterhist(con_ind_inv,sp500_log)
%     xlabel('Equally weighted portfolio')
%     ylabel('True S&P 500')
%     title('Cheking how constructed portfolio looks compared to S&P')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

top_btm=[85 115];
bin_nro=70;
figure
subplot(2,1,1)
    histfit(port_pnl(:,1),bin_nro)
    title('Equally weighted portfolio pnl')
    xlim(top_btm)
subplot(2,1,2)
    histfit(sp500_pnl(:,1),bin_nro) 
    title('True S&P 500 pnl')
    xlim(top_btm)

% Here in the previous P&L picture we can observe similar peaking in
% the P&L figure as in Meuccis paper on Panic Copulas [1]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% P&L in the calm market and in the panic market
calm=port_pnl(below_limit);
panic=port_pnl(above_limit);
[~,bins]=hist(port_pnl,15);
figure
subplot(2,1,1)
    hist(calm,bins)
    title('Equally weighted portfolio P&L in calm')
subplot(2,1,2)
    hist(panic,bins)
    title('Equally weighted portfolio P&L in panic')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Next Flexible probabilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
run FlexibleProbabilities.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Next PanicCopulas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
run PanicCopula.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%