<<<<<<< HEAD
clc;
clear all;
close all;
%% parameter setting
% constant parameters
c = physconst('LightSpeed');% Speed of light in air (m/s)
fc = 77e9;% Center frequency (Hz)
lambda = c/fc;
Rx = 4;
Tx = 2;

% configuration parameters
Fs = 4*10^6;
sweepSlope = 21.002e12;
samples = 128;
loop = 255;
Tc = 60e-6; %us
fft_Rang = 128;
fft_Vel = 256;
fft_Ang = 91;

%% file information
capture_date = '2019_05_09';


folder_location = strcat('D:/RawData/',capture_date);

files = dir(folder_location); % find all the files under the folder
n_files = length(files);

Data_sample = [];
for inum = 3:n_files
    
    file_name = files(inum).name;
    %file_name = '2019_04_09_pms2000';
    % generate file name and folder
    file_location = strcat(folder_location,'/',file_name,'/rad_reo_zerf/adc_data_0.bin');
 

    %% read the data file
    if isfile(file_location)
        eval(['data=readDCA16xx','(file_location);'])
        data_all=reshape(data,size(data,1)*size(data,2),[]); % reshape 4 channels into 1
        data_length=length(data_all);
        Data_sample = [Data_sample; data_all(1:100)'];
    else
        fprintf('not exist file:')
        fprintf(file_name)
    end
end   

% check if there are same rows in Data_sample matrix
[C,IA,~] = unique(Data_sample,'rows');
if size(C,1) == size(Data_sample,1)
    fprintf('no identical files')
else
    fprintf('there are idetical files')
=======
clc;
clear all;
close all;
%% parameter setting
% constant parameters
c = physconst('LightSpeed');% Speed of light in air (m/s)
fc = 77e9;% Center frequency (Hz)
lambda = c/fc;
Rx = 4;
Tx = 2;

% configuration parameters
Fs = 4*10^6;
sweepSlope = 21.002e12;
samples = 128;
loop = 255;
Tc = 60e-6; %us
fft_Rang = 128;
fft_Vel = 256;
fft_Ang = 91;

%% file information
capture_date = '2019_05_09';


folder_location = strcat('D:/RawData/',capture_date);

files = dir(folder_location); % find all the files under the folder
n_files = length(files);

Data_sample = [];
for inum = 3:n_files
    
    file_name = files(inum).name;
    %file_name = '2019_04_09_pms2000';
    % generate file name and folder
    file_location = strcat(folder_location,'/',file_name,'/rad_reo_zerf/adc_data_0.bin');
 

    %% read the data file
    if isfile(file_location)
        eval(['data=readDCA16xx','(file_location);'])
        data_all=reshape(data,size(data,1)*size(data,2),[]); % reshape 4 channels into 1
        data_length=length(data_all);
        Data_sample = [Data_sample; data_all(1:100)'];
    else
        fprintf('not exist file:')
        fprintf(file_name)
    end
end   

% check if there are same rows in Data_sample matrix
[C,IA,~] = unique(Data_sample,'rows');
if size(C,1) == size(Data_sample,1)
    fprintf('no identical files')
else
    fprintf('there are idetical files')
>>>>>>> d89811331dff04df0547cbe4f80d81cc7b1a6de5
end