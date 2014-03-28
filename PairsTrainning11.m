% PairsTrainning11.m
% Estimar parametros con nlos datos de
% entrenamiento

% clear
clear all
close all
clc

%Load data
Stotal = load('Pairs_HistPrices.csv') ;
[N,z] = size(Stotal)
Strain = Stotal( 1 : floor(N/2) + 1,:);
[N,z] = size(Strain)



%Definir ventanas
windowSize = 30 ; %numero de precios
dt = 1/252 ;
Nwindows = N - windowSize ;

%Parametros de la estrategia
stdOpen = 1.7
stdClose = 0.5
maxDays = 5

%Variables de la estrategia
openShort(1) = 0 ;
openLong(1) = 0 ;

%Beta del portafolio abierto
openBeta = zeros(1,Nwindows+1);

for w = 1:Nwindows
    % Estimar score y tau 
    
    %Precios de la ventana
    S = Strain( w : w + windowSize - 1 , :) ;
    
    %Calcular rendimientos
    R = ( S(2:end,:)-S(1:(end-1),:) )./S(1:(end-1),:);

    %Correr regresion lineal
    x = R(:,2) ;
    y = R(:,1) ;
    [P,m,c]=regression(x',y') ;
    beta(w) = m ;

    %Analizar error de la regresion
    error = y - (c + m*x);
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
        openBeta(w) = 0 ;
        if ((score(w) > stdOpen) && (tau(w) < maxDays))
            %Abrir posicion corta
            openShort(w+1) = 1 ;
            openBeta(w) = beta(w);
        end
        if ((score(w) < -stdOpen) && (tau(w) < maxDays))
            %Abrir posicion larga
            openLong(w+1) = 1 ;
            openBeta(w) = beta(w);
        end
    else
        openShort(w+1) = openShort(w) ;
        openLong(w+1) = openLong(w) ;
        openBeta(w) = openBeta(w-1) ;
        
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
subplot(2,1,1)
plot(score)
title('score')
xlabel('window')
hold on
plot(1:Nwindows,stdOpen,'green')
plot(1:Nwindows,-stdOpen,'green')
plot(1:Nwindows,stdClose,'red')
plot(1:Nwindows,-stdClose,'red')

%Grafica de la posicion.
%figure
%plot(openLong-openShort)
%title('Posicion en el primer activo')

%Grafica de la beta
%figure
%plot(beta)
%title('beta')

%Grafica de la openBeta
%hold on
%plot(openBeta,'r')
%title('openBeta')

% Calcular P&L
Swindows = Strain( windowSize : end - 1, : ) ; %Precios al terminar la ventana

% MMA es la Money Market Account
MMA = (openShort(2:end)-openShort(1:end-1)).*(Swindows(:,1)'- openBeta(1:end-1).*Swindows(:,2)') ;
MMA = MMA -(openLong(2:end)-openLong(1:end-1)).*(Swindows(:,1)'-openBeta(1:end-1).*Swindows(:,2)') ;
MMA = cumsum(MMA);
equity = (openLong(2:end)-openShort(2:end)).*(Swindows(:,1)'-openBeta(1:end-1).*Swindows(:,2)');
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

