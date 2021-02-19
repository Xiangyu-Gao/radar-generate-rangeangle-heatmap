function [Detect] = cfar_ca1D_square_fb(Xcube,ref_region,noiseWin,guardLen,Pfa,wrapMode)

N = noiseWin*2;
alpha = N*(Pfa^(-1/N)-1);
alpha_oneside = noiseWin*(Pfa^(-1/noiseWin)-1);
Xcube = Xcube.^2;
Xlength = length(Xcube);
Detect = [];
numOfDet = 0;
if wrapMode == 0    %%% disabled warpped mode
    for i = 1:Xlength
        used_region = zeros(1,Xlength);
        det_region = zeros(1,Xlength);
        if i < noiseWin+guardLen+1  %%% one-sided comparision for left section
            num_noise_block = sum(ref_region(i+guardLen+1:i+guardLen+noiseWin));
            
            % find new sample to replace the old block
            used_region(max(i-guardLen,1):i+guardLen+noiseWin) = 1; % guard region + detection region
            det_region(i+guardLen+1:i+guardLen+noiseWin) = 1; % only detection region
            used_region = max(used_region, ref_region);
           

            det_region(i+guardLen+1:i+guardLen+noiseWin) = xor(det_region(i+guardLen+1:i+guardLen+noiseWin), ...
                ref_region(i+guardLen+1:i+guardLen+noiseWin));          
            free_region = find(~used_region); % find the index of all unused region
            
            if length(free_region) > num_noise_block && num_noise_block > 0
                [~,Id] = sort(abs(free_region-i)); % sort the index with the center i
                det_region(free_region(Id(1:num_noise_block))) = 1;
                det_length = sum(det_region);
                assert(det_length == noiseWin)
            elseif num_noise_block > 0
                det_region(free_region) = 1;
                det_length = sum(det_region);
            else
                det_length = sum(det_region);
            end
            
            noise_estimate = sum(Xcube(find(det_region)))/det_length;
            alpha_oneside_new= det_length*(Pfa^(-1/det_length)-1);
            if Xcube(i) > alpha_oneside_new*noise_estimate
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noise_estimate;  %%% estimated noise
            end
            
        elseif i < Xlength-noiseWin-guardLen+1  %%% two-sided comparison for middle section
            num_noise_block = sum(ref_region(i+guardLen+1:i+guardLen+noiseWin)) ...
                + sum(ref_region(i-guardLen-noiseWin:i-guardLen-1));
            
            % find new sample to replace the old block
            used_region(i-guardLen-noiseWin:i+guardLen+noiseWin) = 1; % guard region + detection region
            det_region(i+guardLen+1:i+guardLen+noiseWin) = 1; % only right detection region
            det_region(i-guardLen-noiseWin:i-guardLen-1) = 1; % only left detection region
            used_region = max(used_region, ref_region);
            det_region(i+guardLen+1:i+guardLen+noiseWin) = xor(det_region(i+guardLen+1:i+guardLen+noiseWin), ...
                ref_region(i+guardLen+1:i+guardLen+noiseWin));
            det_region(i-guardLen-noiseWin:i-guardLen-1) = xor(det_region(i-guardLen-noiseWin:i-guardLen-1), ...
                ref_region(i-guardLen-noiseWin:i-guardLen-1));
            free_region = find(~used_region); % find the index of all unused region
            
            if length(free_region) > num_noise_block && num_noise_block > 0
                [~,Id] = sort(abs(free_region-i)); % sort the index with the center i
                det_region(free_region(Id(1:num_noise_block))) = 1;
                det_length = sum(det_region);
                assert(det_length == noiseWin*2)
            elseif num_noise_block > 0
                det_region(free_region) = 1;
                det_length = sum(det_region);
            else
                det_length = sum(det_region);
            end
            
            noise_estimate = sum(Xcube(find(det_region)))/det_length;
            alpha_new= det_length*(Pfa^(-1/det_length)-1);
            if Xcube(i) > alpha_new*noise_estimate
                numOfDet = numOfDet + 1;
                Detect(1,numOfDet) = i; %%% index
                Detect(2,numOfDet) = Xcube(i);  %%% object power
                Detect(3,numOfDet) = noise_estimate;  %%% estimated noise
            end
          
        else     %%%  one-sided comparision for right section
            num_noise_block = sum(ref_region(i-guardLen-noiseWin:i-guardLen-1));
            
            % find new sample to replace the old block
            used_region(i-guardLen-noiseWin:min(i+guardLen,Xlength)) = 1; % guard region + detection region
            det_region(i-guardLen-noiseWin:i-guardLen-1) = 1; % only detection region
            used_region = max(used_region, ref_region);
            det_region(i-guardLen-noiseWin:i-guardLen-1) = xor(det_region(i-guardLen-noiseWin:i-guardLen-1), ...
                ref_region(i-guardLen-noiseWin:i-guardLen-1));
            free_region = find(~used_region); % find the index of all unused region
            
            if length(free_region) > num_noise_block && num_noise_block > 0
                [~,Id] = sort(abs(free_region-i)); % sort the index with the center i
                det_region(free_region(Id(1:num_noise_block))) = 1;
                det_length = sum(det_region);
                assert(det_length == noiseWin)
            elseif num_noise_block > 0
                det_region(free_region) = 1;
                det_length = sum(det_region);
            else
                det_length = sum(det_region);
            end
            
            noise_estimate = sum(Xcube(find(det_region)))/det_length;
            alpha_oneside_new= det_length*(Pfa^(-1/det_length)-1);
            
            if Xcube(i) > alpha_oneside_new*noise_estimate
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