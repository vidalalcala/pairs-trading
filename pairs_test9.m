% pairs_test9.m
% Implementacion del test de
% "Pairs trading" en Matlab
% para la clase CDF , 9-11 am .

% clear
clear all
close all
clc

%Load data
Sfull = load('Pairs_HistPrices.csv') ;
[N,z] = size(Sfull)
Stest = Sfull(floor(N/2)+1:end,:);
[N,z] = size(Stest)

%Parametros
windowSize = 30 ;%numero de rendimientos
dt = 1/252 ;
stdOpen = 1.40 ;
stdClose = 1.05 ;
maxDays = 8 ;

%Numero de ventanas
Nwindows = N - windowSize - 1 ;

%Valores iniciales de la estrategia
openShort(1) = 0 ; % Posicion al llegar a la ventana
openLong(1) = 0 ;
betaOpen = zeros( 1 , Nwindows+1); % Beta del portafolio abierto

for w = 1:Nwindows
    S = Stest(w : w + windowSize , : ) ;
    R = (S(2:end,:)-S(1:end-1,:))./S(1:end-1,:);
    
    %Correr regresion lineal de rendimientos
    x = R(1:windowSize,2) ;
    y = R(1:windowSize,1) ;
    [P,m,b] = regression( x' ,y') ;
    error = y-(b + m*x);
    beta(w) = m ;
    
    %Calcular proceso autoregresivo
    X = cumsum(error);
    
    %Calcular score
    x = X(1:end-1) ;
    y = X(2:end);
    [P,a,b] = regression( x' ,y') ;
    
    k(w) = (1-a)/dt ; 
    m(w) = b/(1-a) ;
    tau(w) = 1/(k(w)*dt) ;
    xi = (y -(b+a*x));
    sigma(w) = sqrt(var(xi)/dt) ;
    sigma_eq(w) = sqrt(var(xi)/(1-a^2));
    score(w) = (X(end)- m(w))/sigma_eq(w);
    
    %Estrategia
    if ( (openShort(w) < 0.5)  && (openLong(w) < 0.5 ))
        % Ambos portafolios cerrados
        openShort(w+1) = 0 ;
        openLong(w+1) = 0 ;
        betaOpen(w) = 0;
        if ((score(w) > stdOpen) && (tau(w) < maxDays))
            %Sell to open
            openShort(w+1) = 1 ;
            betaOpen(w) = beta(w) ;
        end
        
        if ((score(w) < -stdOpen) && (tau(w) < maxDays))
            %Buy to open
            openLong(w+1) = 1 ;
            betaOpen(w) = beta(w) ;
        end
           
    else
        % Un portafolio abierto
        betaOpen(w) = betaOpen(w-1) ;
        openShort(w+1) = openShort(w) ;
        openLong(w+1) = openLong(w) ;
        
        if (openShort(w) > 0.5)
            if ( score(w) < stdClose )
                openShort(w+1) = 0 ;
            end            
        end
        
        if (openLong(w) > 0.5)
            if ( score(w) > -stdClose )
                openLong(w+1) = 0 ;
            end            
        end
        
    end    
end
subplot(2,1,1)
plot(score)
title('Score')
xlabel('ventana')
hold on
plot(1:Nwindows , stdOpen , 'g')
plot(1:Nwindows , -stdOpen , 'g')
plot(1:Nwindows , stdClose , 'r')
plot(1:Nwindows , -stdClose , 'r')

% Calcular P&L
Swindows = Stest( windowSize + 1  : end - 1, : ) ; %Precios al terminar la ventana

% MMA es la Money Market Account
MMA = (openShort(2:end)-openShort(1:end-1)).*(Swindows(:,1)'- betaOpen(1:end-1).*Swindows(:,2)') ;
MMA = MMA -(openLong(2:end)-openLong(1:end-1)).*(Swindows(:,1)'-betaOpen(1:end-1).*Swindows(:,2)') ;
MMA = cumsum(MMA);
equity = (openLong(2:end)-openShort(2:end)).*(Swindows(:,1)'-betaOpen(1:end-1).*Swindows(:,2)');
PL = MMA + equity;

%figure
%plot(MMA)
%title('MMA')

%figure
%plot(equity)
%title('Portfolio equity')

subplot(2,1,2)
plot(PL)
title('Portfolio PL')
ylabel('dollars')




