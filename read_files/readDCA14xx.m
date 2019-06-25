%%% This script is used to read the binary file produced by the DCA1000
%%% and Radar Studio
%%% Command to run in Matlab GUI - readTSW14xx('<ADC capture bin file>')
function [retVal] = readDCA14xx(fileName)
%% global variables
% change based on sensor config
%----------------------------------------------------------------------
numADCBits = 16; % number of ADC bits per sample
numLanes = 4; % do not change. number of lanes is always 4 even if only 1 lane is used. unused lanes
isReal = 0; % set to 1 if real only data, 0 if complex dataare populated
% with 0
%----------------------------------------------------------------------
%% read file and convert to signed number
% read .bin file
fid = fopen(fileName,'r');
adcData = fread(fid,'uint16');
% compensate for offset binary format
adcData = adcData-2^15;
% if 12 or 14 bits ADC per sample compensate for sign extension
if numADCBits ~= 16
l_max=2^(numADCBits-1)-1;
adcData(adcData>l_max) = adcData(adcData>l_max) - 2^numADCBits;
end
fclose(fid);
%% organize data by LVDS lane
% reshape data based on two samples per LVDS lane
adcData = reshape(adcData, numLanes*2, []);
% for real only data
if isReal
%each LVDS lane contains two samples from each RX
rxSample1 = adcData([1,2,3,4],:);
rxSample2 = adcData([5,6,7,8],:);
% interleave the first sample set and the second sample set
adcData = reshape([rxSample1;rxSample2], size(rxSample1,1), []);
%for complex data
else
% combine real and imaginary parts of complex number
adcData = adcData([1,2,3,4],:) + sqrt(-1)*adcData([5,6,7,8],:);
end
%% return receiver data

retVal = adcData;