% DC Range calibration config message to datapath
function [Rangedata_chirp1,caliDcRange] = caliDcRangeSig(Xcube,i,loop,frame_start,caliDcRange_old,cali_n)
% cali_n, the range bins need to be calibrated
for anti = 1:4
    if rem(i,20) == 1 || i == frame_start
        caliDcRange(:,anti) = sum(squeeze(Xcube(:,anti,:)),2)/loop;
    else
        caliDcRange = caliDcRange_old;
    end
    % remove DC
    Xcube(1:cali_n,anti,:) = Xcube(1:cali_n,anti,:) - repmat(caliDcRange(1:cali_n,anti),...
        1,size(Xcube(1:cali_n,anti,:),2),size(Xcube(1:cali_n,anti,:),3));
    Rangedata_chirp1 = Xcube;
end
end