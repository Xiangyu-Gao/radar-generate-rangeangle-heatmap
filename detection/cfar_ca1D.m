function [Detect] = cfar_ca1D(Xcube,noiseWin,guardLen,Thres,wrapMode)

divShift1 = log2(2*noiseWin);   %%% for two-sided
divShift2 = log2(2*noiseWin/2);   %%% for one-sided
Xcube = log2(abs(Xcube));
Xlength = length(Xcube);
Detect = [];
numOfDet = 0;
if wrapMode == 0    %%% disabled warpped mode
    for i = 1:Xlength
        if i < noiseWin+guardLen+1  %%% one-sided comparision for left section
            noiseSum = sum(Xcube(i+guardLen+1:i+guardLen+noiseWin));
            if Xcube(i) > noiseSum/2^divShift2 + Thres
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noiseSum;  %%% estimated noise
            end
        elseif i < Xlength-noiseWin-guardLen+1  %%% two-sided comparison for middle section
            noiseSum = sum(Xcube(i+guardLen+1:i+guardLen+noiseWin))+sum(Xcube(i-guardLen-noiseWin:i-guardLen-1));
            if Xcube(i) > noiseSum/2^divShift1 + Thres
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noiseSum;  %%% estimated noise
            end
        else     %%%  one-sided comparision for right section
            noiseSum = sum(Xcube(i-guardLen-noiseWin:i-guardLen-1));
            if Xcube(i) > noiseSum/2^divShift2 + Thres
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noiseSum;  %%% estimated noise
            end
        end
    end
else       %%% enabled wrapped mode
    for i = 1:Xlength
        if i < noiseWin+guardLen+1  %%% two-sided comparision for left section with wrap
            %%% discuss the wrap scenario
            if i <= guardLen
                noiseSum = sum(Xcube(i+guardLen+1:i+guardLen+noiseWin))+sum(Xcube(Xlength+i-guardLen-noiseWin:Xlength+i-guardLen-1));
            else 
                noiseSum = sum(Xcube(i+guardLen+1:i+guardLen+noiseWin))+sum(Xcube(Xlength+i-guardLen-noiseWin:Xlength))+sum(Xcube(1:i-1-guardLen));
            end
           
            if Xcube(i) > noiseSum/2^divShift1 + Thres
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noiseSum;  %%% estimated noise
            end
            
        elseif i < Xlength-noiseWin-guardLen+1  %%% two-sided comparison for middle section
            noiseSum = sum(Xcube(i+guardLen+1:i+guardLen+noiseWin))+sum(Xcube(i-guardLen-noiseWin:i-guardLen-1));
            if Xcube(i) > noiseSum/2^divShift1 + Thres
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noiseSum;  %%% estimated noise
            end
            
        else     %%%  two-sided comparision for right section with wrap
            if i >= Xlength-guardLen+1
                noiseSum = sum(Xcube(i-guardLen-noiseWin:i-guardLen-1))+sum(Xcube(guardLen+i-Xlength+1:guardLen+i-Xlength+noiseWin));
            else
                noiseSum = sum(Xcube(i-guardLen-noiseWin:i-guardLen-1))+sum(Xcube(guardLen+i+1:Xlength))+sum(Xcube(1:noiseWin-Xlength+i+guardLen));
            end
            
            if Xcube(i) > noiseSum/2^divShift1 + Thres
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noiseSum;  %%% estimated noise
            end
        end
    end
end
end