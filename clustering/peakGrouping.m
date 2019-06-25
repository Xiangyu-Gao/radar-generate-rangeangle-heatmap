function [objOut] = peakGrouping(objRaw,detMat,numDopplerBins,numRangeBins,numDetectedObjects)

maxRangeIdx = numRangeBins-1;
minRangeIdx = numRangeBins/2+1;
numObjOut = 0;
objOut = [];
% define the 3 para operation "? :"
ifelse = @(a,b,c)(a ~= 0)*b+(a == 0)*c; 
for ni = 1:numDetectedObjects
    detectedObjFlag = 0;
    rangeIdx = objRaw(1,ni);
    dopplerIdx = objRaw(2,ni);
    peakVal = detMat(1,ni);
    kernal = zeros(3,3);
   
    if rangeIdx <= maxRangeIdx && rangeIdx >= minRangeIdx
        detectedObjFlag = 1;
        % fill the middle column of the  kernel
        kernal(2,2) = peakVal;
        if ni > 1
            if objRaw(1,ni-1) == rangeIdx-1 && objRaw(2,ni-1) == dopplerIdx
                kernal(1,2) = detMat(1,ni-1);
            end
        end
        if ni < numDetectedObjects
            if objRaw(1,ni+1) == rangeIdx+1 && objRaw(2,ni+1) == dopplerIdx
                kernal(3,2) = detMat(1,ni+1);
            end
        end
        % fill the left column of the kernal
        k = ni-1;
        if k < 1
            k = k+numDetectedObjects;
        end
        for L = 1:numDetectedObjects
            
            if objRaw(2,k) == ifelse(dopplerIdx-2 > 0,dopplerIdx-2,dopplerIdx-2+numDopplerBins)
                break;
            end
            if objRaw(1,k) == rangeIdx+1 && objRaw(2,k) == ifelse(dopplerIdx-1 > 0,dopplerIdx-1,dopplerIdx-1+numDopplerBins)
                kernal(3,1) = detMat(1,k);
            elseif objRaw(1,k) == rangeIdx && objRaw(2,k) == ifelse(dopplerIdx-1 > 0,dopplerIdx-1,dopplerIdx-1+numDopplerBins)
                kernal(2,1) = detMat(1,k);
            elseif objRaw(1,k) == rangeIdx-1 && objRaw(2,k) == ifelse(dopplerIdx-1 > 0,dopplerIdx-1,dopplerIdx-1+numDopplerBins)
                kernal(1,1) = detMat(1,k);
            end
            k=k-1;
            if k < 1
                k = k+numDetectedObjects;
            end
        end
        % Fill the right column of the kernel
        k = ni+1;
        if k > numDetectedObjects
            k = k-numDetectedObjects;
        end
        for L = 1:numDetectedObjects
            if objRaw(2,k) == ifelse(dopplerIdx+2 > numDopplerBins,dopplerIdx+2-numDopplerBins,dopplerIdx+2)
                break;
            end
            if objRaw(1,k) == rangeIdx-1 && objRaw(2,k) == ifelse(dopplerIdx+1 > numDopplerBins,dopplerIdx+1-numDopplerBins,dopplerIdx+1)
                kernal(1,3) = detMat(1,k);
            elseif objRaw(1,k) == rangeIdx && objRaw(2,k) == ifelse(dopplerIdx+1 > numDopplerBins,dopplerIdx+1-numDopplerBins,dopplerIdx+1)
                kernal(2,3) = detMat(1,k);
            elseif objRaw(1,k) == rangeIdx+1 && objRaw(2,k) == ifelse(dopplerIdx+1 > numDopplerBins,dopplerIdx+1-numDopplerBins,dopplerIdx+1)
                kernal(3,3) = detMat(1,k);
            end 
            k=k+1;
            if k > numDetectedObjects
                k = k-numDetectedObjects;
            end        
        end
        % Compare the detected object to its neighbors.Detected object is
        % at index [2,2]
        if kernal(2,2) ~= max(max(kernal))
            detectedObjFlag = 0;
        end      
    end
    if detectedObjFlag == 1
        objOut = [objOut,zeros(3,1)];
        numObjOut = numObjOut+1;
        objOut(1,numObjOut) = rangeIdx;
        objOut(2,numObjOut) = dopplerIdx;
        objOut(3,numObjOut) = peakVal;
    end
end        
end