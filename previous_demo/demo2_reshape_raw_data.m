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

% change the file location and the number of frames you need
file_location = '/mnt/disk1/RAW RADAR DATA/radar_data_20190409/2019_04_09_pms1000/rad_reo_zerf/adc_data_0.bin';
frame_end = 10;
%% read the data file
eval(['data=readDCA16xx','(file_location);'])
data_all=reshape(data,size(data,1)*size(data,2),[]); % reshape 4 channels into 1
data_length=length(data_all);
data_each_frame=samples*loop*2*Rx;
Frame_num=data_length/data_each_frame;
% check whether Frame number is an integer
if Frame_num == fix(Frame_num)

else
    fprintf('Frame number is not an integer\n')
    if frame_end > fix(Frame_num)
        frame_end = fix(Frame_num);
    end
end

Xcube_chirp_All_Frame = [];

for i=1:frame_end % 1:end frame, Note:start frame must be 1
    
    % seperate each frame and reshape the raw data to foramt [samples,antennas,chirps]
    Framedata(:,i)=data_all(((i-1)*data_each_frame+1):i*data_each_frame);
    Frame_loop(:,:,i)=reshape(Framedata(:,i),samples*4,[]);
    Frame_loop_chirp1(:,:,i)=Frame_loop(:,1:2:end,i);
    Frame_loop_chirp2(:,:,i)=Frame_loop(:,2:2:end,i);
    for jj=1:loop
        Frame_loop_chirp1_Rx(:,:,jj,i)=reshape(Frame_loop_chirp1(:,jj,i),[samples Rx]);
        Frame_loop_chirp2_Rx(:,:,jj,i)=reshape(Frame_loop_chirp2(:,jj,i),[samples Rx]);
    end
    Xcube_chirp1 = permute(Frame_loop_chirp1_Rx(:,:,:,i),[1 2 3]);
    Xcube_chirp2 = permute(Frame_loop_chirp2_Rx(:,:,:,i),[1 2 3]);
    Xcube_chirp_all_antena = cat(2,Xcube_chirp1,Xcube_chirp2);
    Xcube_chirp_All_Frame = cat(3,Xcube_chirp_All_Frame,Xcube_chirp_all_antena);
end