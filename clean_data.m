

%Weekly total return indices

%eurostoxx, sp500, sp500 constituents, vix
temp=[];
temp=[temp min(sp500_dates)];
temp=[temp min(stock_dates)];
temp=[temp min(eurostox_dates)];
temp=[temp min(vix_dates)];

startDate=max(temp);

startInd=[];
startInd=[startInd find(sp500_dates==startDate)];
startInd=[startInd find(stock_dates==startDate)];
startInd=[startInd find(eurostox_dates==startDate)];
startInd=[startInd find(vix_dates==startDate)];


sp500_dates2=sp500_dates(startInd(1):end);
stock_dates2=stock_dates(startInd(2):end);
eurostox_dates2=eurostox_dates(startInd(3):end);
vix_dates2=vix_dates(startInd(4):end);

sp500_prices2=sp500_prices(startInd(1):end);
stock_prices2=stock_prices(startInd(2):end,:);
eurostox_prices2=eurostox_prices(startInd(3):end);
vix_prices2=vix_prices(startInd(4):end);


[isNan_i,isNan_j]=find(isnan(stock_prices2));
stock_prices2(isNan_i,isNan_j)=stock_prices2(isNan_i-1,isNan_j);

%Invariants
sp500_log=log(sp500_prices2(2:end)./sp500_prices2(1:(end-1)));
stock_log=log(stock_prices2(2:end,:)./stock_prices2(1:(end-1),:));
eurostox_log=log(eurostox_prices2(2:end)./eurostox_prices2(1:(end-1)));


% Indices
sp500_ind=ones(size(sp500_dates2))*100;
stock_ind=ones(size(stock_prices2))*100;
eurostox_ind=ones(size(eurostox_dates2))*100;

% Index propagation
T=length(sp500_dates2);
for t=2:T
    sp500_ind(t)=sp500_ind(t-1)*exp(sp500_log(t-1));
    eurostox_ind(t)=eurostox_ind(t-1)*exp(eurostox_log(t-1));
    stock_ind(t,:)=stock_ind(t-1,:).*exp(stock_log(t-1,:));
end

% Let's plot what we got
figure
subplot(3,1,1)
    plot(sp500_dates2,sp500_ind,'k')
    hold on
    plot(eurostox_dates2,eurostox_ind,'b')
    legend('S&P 500','EuroStoxx','location','NorthWest')
    hold off
    title('Equity indices')
    xlim([min(vix_dates2) max(vix_dates2)])
    grid on
subplot(3,1,2)
    plot(stock_dates2,stock_ind,'b')
    title('S&P 500 constituents')
    ylim([0 8000])
    xlim([min(vix_dates2) max(vix_dates2)])
    grid on
subplot(3,1,3)
    plot(vix_dates2,vix_prices2,'b')
    title('VIX index')
    xlim([min(vix_dates2) max(vix_dates2)])
    grid on