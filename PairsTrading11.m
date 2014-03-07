% estrategiaPairs.m
% Estimar parametros de una estrategia simple

% clear
clear all
close all
clc

%Load data
Stotal = load('Pairs_HistPrices.csv') ;
[N,z] = size(Stotal)

%Definir ventanas
windowSize = 60 ;
dt = 1/252 ;
Nwindows = N - windowSize ;


for w = 1:Nwindows
    % Estimar score y tau 
    
    %Precios de la ventana
    S = Stotal( w : w + windowSize - 1 , :)
    
    %Calcular rendimientos
    R = ( S(2:end,:)-S(1:(end-1),:) )./S(1:(end-1),:);

    %Correr regresion lineal
    x = R(1:windowSize,2) ;
    y = R(1:windowSize,1) ;
    [P,m,b]=regression(x',y') ;


    %Analizar error de la regresion
    error = y - (b + m*x);
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
    sigma_eq(w) = sigma*sigma/(1-m^2) ;
    desv = sigma_eq(w)*sqrt(dt) ;
    score(w) = (W(end)-n(w))/sigma_eq(w) ;
end