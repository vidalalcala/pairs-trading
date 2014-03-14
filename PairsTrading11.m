% PairsTrading11.m
% Estimar parametros de una estrategia simple

% clear
clear all
close all
clc

%Load data
Stotal = load('Pairs_HistPrices.csv') ;
[N,z] = size(Stotal)

%Definir ventanas
windowSize = 60 ; %numero de precios
dt = 1/252 ;
Nwindows = N - windowSize ;

%Parametros de la estrategia
stdOpen = 2.0
stdClose = 1.0

%Variables de la estrategia
openShort(1) = 0 ;
openLong(1) = 0 ;

%Definir P&L de la estrategia
PL(1) = 0 ;

%Money Market account
MMA(1) = 0 ;
r = 0.02 ; %Tasa de interes anual

for w = 1:Nwindows
    % Estimar score y tau 
    
    %Precios de la ventana
    S = Stotal( w : w + windowSize - 1 , :) ;
    
    %Calcular rendimientos
    R = ( S(2:end,:)-S(1:(end-1),:) )./S(1:(end-1),:);

    %Correr regresion lineal
    x = R(:,2) ;
    y = R(:,1) ;
    [P,m,beta]=regression(x',y') ;

    %Analizar error de la regresion
    error = y - (beta + m*x);
    W = cumsum(error) ;

    % Calcular coeficientes del
    % proceso OU

    x = W(1:end-1) ;
    y = W(2:end) ;
    [P,m,b]=regression(x',y') ;
    k = (1-m)/dt ;
    n(w) = b/(1-m) ;
    tau(w) = 1/(k*dt) ;
    xi = y - (b + m*x) ;
    sigma = sqrt(var(xi)/dt) ;
    sigma_eq(w) = sqrt(var(xi)/(1-m^2)) ;
    score(w) = (W(end)-n(w))/sigma_eq(w) ;
    
    %Implementar estrategia
    
    if ( (openShort(w) < 0.5) && (openLong(w) < 0.5) )
        % El caso sin posiciones abiertas.
        openShort(w+1)=0 ;
        openLong(w+1)=0 ;
        if (score(w) > stdOpen)
            %Abrir posicion corta
            openShort(w+1) = 1 ;
        end
        if (score(w) < -stdOpen)
            %Abrir posicion larga
            openLong(w+1) = 1 ;
        end
    else
        openShort(w+1) = openShort(w) ;
        openLong(w+1) = openLong(w) ;
        
        if (openShort(w) > 0.5)
            % El caso de posicion corta abierta
            if ( score(w) < stdClose)
                %Se cierra la posicion
                openShort(w+1) = 0 ;
            end
        end
        if (openLong(w) > 0.5)
            % El caso de posicion larga abierta
            if ( score(w) > -stdClose)
                %Se cierra la posicion
                openLong(w+1) = 0 ;
            end
        end
    end
        
    
end

%Grafica del score
plot(score)
title('score')
xlabel('window')
hold on
plot(1:Nwindows,stdOpen,'green')
plot(1:Nwindows,-stdOpen,'green')
plot(1:Nwindows,stdClose,'red')
plot(1:Nwindows,-stdClose,'red')

%Grafica de la posicion.
figure
plot(openLong)
hold on
plot(openShort,'red')


