clc;
clear all;
close all;
Is_Windowed = 1;
Tc = 120e-6; % us
c = physconst('LightSpeed');% Speed of light in air (m/s)
fc = 77e9; % Center frequency (Hz)
lambda = c/fc;
fft_Rang = 134;
Fs = 4*10^6;
sweepSlope = 21.0017e12;
samples = 128;
fft_Ang = 128;

freq_res = Fs/fft_Rang;% range_grid
freq_grid = (0:fft_Rang-1).'*freq_res;
rng_grid = freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;
rng_grid = rng_grid(4:fft_Rang-3); % crop rag_grid

dop_grid = fftshiftfreqgrid(128,1/Tc); % velocity_grid, now fs is equal to 1/Tc
vel_grid = dop_grid*lambda/2;   % unit: m/s, v = lamda/4*[-fs,fs], dopgrid = [-fs/2,fs/2]

w = linspace(-1,1,fft_Ang); % angle_grid
agl_grid = asin(w)*180/pi; % [-1,1]->[-pi/2,pi/2]

file_dir = '/media/admin-cmmb/Elements/CRdataset/2019_04_09/2019_04_09_pms1001/WIN_R_MAT/2019_04_09_pms1001_000300.mat'
% file_dir = '/media/admin-cmmb/Elements/CRdataset/2019_04_09/2019_04_09_pss1003/WIN_R_MAT/2019_04_09_pss1003_000005.mat'
data = load(file_dir).R_data;
data = data - mean(data, 3);
AngData = fft_angle(data, 128, Is_Windowed);
% figure('visible','off')
figure()
set(gcf,'Position',[10,10,530,420])
[axh] = surf(agl_grid,rng_grid,squeeze(abs(AngData(:,:,1))));
view(0,90)
axis([-60 60 0.6 8]);
% axis([-60 60 1 25]);
grid off
shading interp
xlabel('Azimuth angle (deg)')
ylabel('Range (m)')
colorbar
caxis([0.1, 0.6])
title('Range-Angle heatmap')