clc;
clear all;
close all;

%% parameter setting
c = physconst('LightSpeed');                % Speed of light in air (m/s)
fc = 77e9;                                  % Center frequency (Hz)
lambda = c/fc;
Fs = 4*10^6;
sweepSlope = 21.0017e12;
samples = 128;
loop = 128;

Rx = 4;
Tx = 2;
Tc = 240e-6; % us

fft_Rang = 256;
fft_Vel = 128;
fft_Ang = 181;

% Creat grid table First
% range_grid
freq_res = Fs/fft_Rang;
freq_grid = (0:fft_Rang-1).'*freq_res;
rng_grid = freq_grid*c/sweepSlope/2;%%% d=frediff_grid*c/sweepSlope/2;

% angle_grid
w = [-180:2:180];
agl_grid=asin(w/180)*180/pi; % [-1,1]->[-pi/2,pi/2]

% vel_grid
num_rng_samples=samples;    %%% the Fast time Signal length is 128. The forresponding sampling frequency of Slow time Signal is Fs/128
dop_grid=fftshiftfreqgrid(fft_Vel,1/Tc);
vel_grid=dop_grid*lambda/2;   %%%% m/s
% vel_grid=3.6*vel_grid;        %%%% km/hm/h
%% #################### Range-doppler FFT ########################

%% read data
tempdata = load('C:\Users\Administrator\Desktop\temp_data\Xcube0231_441.mat');
data1 = tempdata.Xcube_chirp1;

%% Range FFT and Doppler FFT
[Rangedata_chirp1,Dopdata_chirp1,~]=fft_Radar(data1,fft_Rang,fft_Vel,fft_Ang);

%% Plot Range-doppler heatmap
figure()
mesh(vel_grid,rng_grid,abs(squeeze(Dopdata_chirp1(:,1,:))));
view(0,90)
axis([-4,4,0,28])
title('Range-doppler heatmap')
xlabel('Velocity m/s')
ylabel('Range m')

%% ########################## STFT #################################

%% read data
tempdata = load('C:\Users\Administrator\Desktop\temp_data\Xcube0231_438.mat');
data1 = tempdata.Xcube_chirp1;
tempdata = load('C:\Users\Administrator\Desktop\temp_data\Xcube0231_439.mat');
data2 = tempdata.Xcube_chirp1;
tempdata = load('C:\Users\Administrator\Desktop\temp_data\Xcube0231_440.mat');
data3 = tempdata.Xcube_chirp1;
tempdata = load('C:\Users\Administrator\Desktop\temp_data\Xcube0231_441.mat');
data4 = tempdata.Xcube_chirp1;
tempdata = load('C:\Users\Administrator\Desktop\temp_data\Xcube0231_442.mat');
data5 = tempdata.Xcube_chirp1;

%% Range FFT for each data file
concatenate_Rangedata = [];
for i=1:5
    eval(['data = data',num2str(i),';']);
    [Rangedata_chirp1,~,~] = fft_Radar(data,fft_Rang,fft_Vel,fft_Ang);
    %%% record the maximum Range peak for each dataset
    temp_Rangedata = squeeze(Rangedata_chirp1(:,1,1));
    [~,index] =  max(abs(temp_Rangedata))
    concatenate_Rangedata = [concatenate_Rangedata;squeeze(Rangedata_chirp1(index,1,:))];
end

%% STFT
WINDOW =  64;
NOVEPLAP = 32;

[S,F,T] = spectrogram(concatenate_Rangedata,WINDOW,NOVEPLAP,64,1/Tc,'centered');
v_grid_new = F*lambda/2;

%% plot figure
figure()
surf(T-T(1),v_grid_new,abs(S))
view(0,90)
xlabel('time /s')
ylabel('velocity m/s')
title('SFFT heatmap')