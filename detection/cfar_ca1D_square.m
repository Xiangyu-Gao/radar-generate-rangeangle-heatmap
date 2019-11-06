function [Detect] = cfar_ca1D_square(Xcube,noiseWin,guardLen,Pfa,wrapMode)

N = noiseWin*2;
alpha = N*(Pfa^(-1/N)-1);
alpha_oneside = noiseWin*(Pfa^(-1/noiseWin)-1);
Xcube = Xcube.^2;
Xlength = length(Xcube);
Detect = [];
numOfDet = 0;
if wrapMode == 0    %%% disabled warpped mode
    for i = 1:Xlength
        if i < noiseWin+guardLen+1  %%% one-sided comparision for left section
            noise_estimate = sum(Xcube(i+guardLen+1:i+guardLen+noiseWin))/noiseWin;
            if Xcube(i) > alpha_oneside*noise_estimate
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noise_estimate;  %%% estimated noise
            end
        elseif i < Xlength-noiseWin-guardLen+1  %%% two-sided comparison for middle section
            noise_estimate = (sum(Xcube(i+guardLen+1:i+guardLen+noiseWin)) ...
                + sum(Xcube(i-guardLen-noiseWin:i-guardLen-1)))/N;
            if Xcube(i) > alpha*noise_estimate
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noise_estimate;  %%% estimated noise
            end
        else     %%%  one-sided comparision for right section
            noise_estimate = sum(Xcube(i-guardLen-noiseWin:i-guardLen-1))/noiseWin;
            if Xcube(i) > alpha_oneside*noise_estimate
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noise_estimate;  %%% estimated noise
            end
        end
    end
else       %%% enabled wrapped mode
    for i = 1:Xlength
        if i < noiseWin+guardLen+1  %%% two-sided comparision for left section with wrap
            %%% discuss the wrap scenario
            if i <= guardLen
                noise_estimate = (sum(Xcube(i+guardLen+1:i+guardLen+noiseWin))...
                    + sum(Xcube(Xlength+i-guardLen-noiseWin:Xlength+i-guardLen-1)))/N;
            else 
                noise_estimate = (sum(Xcube(i+guardLen+1:i+guardLen+noiseWin))...
                    + sum(Xcube(Xlength+i-guardLen-noiseWin:Xlength))+sum(Xcube(1:i-1-guardLen)))/N;
            end
           
            if Xcube(i) > alpha*noise_estimate
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noise_estimate;  %%% estimated noise
            end
            
        elseif i < Xlength-noiseWin-guardLen+1  %%% two-sided comparison for middle section
            noise_estimate = (sum(Xcube(i+guardLen+1:i+guardLen+noiseWin))...
                + sum(Xcube(i-guardLen-noiseWin:i-guardLen-1)))/N;
            if Xcube(i) > alpha*noise_estimate
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noise_estimate;  %%% estimated noise
            end
            
        else     %%%  two-sided comparision for right section with wrap
            if i >= Xlength-guardLen+1
                noise_estimate = (sum(Xcube(i-guardLen-noiseWin:i-guardLen-1))...
                    + sum(Xcube(guardLen+i-Xlength+1:guardLen+i-Xlength+noiseWin)))/N;
            else
                noise_estimate = (sum(Xcube(i-guardLen-noiseWin:i-guardLen-1))...
                    + sum(Xcube(guardLen+i+1:Xlength))+sum(Xcube(1:noiseWin-Xlength+i+guardLen)))/N;
            end
            
            if Xcube(i) > alpha*noise_estimate
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noise_estimate;  %%% estimated noise
            end
        end
    end
end
end