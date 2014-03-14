% pairs_trading_9.m

% clear
clear all
close all
clc

%Load data
Sfull = load('Pairs_HistPrices.csv') ;
[N,z] = size(Sfull)

%Parametros
windowSize = 63 ;%numero de rendimientos
dt = 1/252 ;

%Numero de ventanas
Nwindows = N - windowSize - 1 ;

for w = 1:Nwindows
    S = Sfull(w : w + windowSize , : )
    R = (S(2:end,:)-S(1:end-1,:))./S(1:end-1,:);
    
    %Correr regresion lineal de rendimientos
    x = R(1:windowSize,2) ;
    y = R(1:windowSize,1) ;
    [P,m,b] = regression( x' ,y') ;
    error = y-(b + m*x);
    
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
    sigma2(w) = var(xi)/dt ;
    sigma2_eq(w) = var(xi)/(1-b^2);
    score(w) = (X(end)- m(w))/sqrt(sigma2_eq(w));
end
plot(score)
title('Score')
xlabel('ventana')