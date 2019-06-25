clc;
clear all;
close all;

%% parameter setting
c = physconst('LightSpeed');                % Speed of light in air (m/s)
fc = 77e9;                                  % Center frequency (Hz)
lambda = c/fc;
antennaDist = lambda/2;                     % distance between antennas
Fs = 4*10^6;
sweepSlope = 21.0017e12;
samples = 128;
loop = 255; % # chirps

Rx = 4;
Tx = 2;
Tc = 240e-6; % us

fft_Rang = 256;
fft_Vel = 256;
fft_Ang = 181;

%% Reshape data
% change the file location
file_location = 'pedestrian.bin';
%% read the data file
eval(['data=readDCA16xx','(file_location);']);
data_all=reshape(data,size(data,1)*size(data,2),[]); % reshape 4 channels into 1
data_length=length(data_all);
data_each_frame=samples*loop*2*Rx;
Frame_num=data_length/data_each_frame;
%% Modifications
frame_start = 1; % Modifations: start from the first frame
frame_end = 900; % Modifations: we have 900 frames in each file

% check whether Frame number is an integer
if Frame_num == 900
    frame_start = 1;
else
    fprintf('Frame number is not an integer\n')
    frame_start = 900 - fix(Frame_num)+1;
    % zero fill the data_all
    num_zero_fill = 900*data_each_frame - data_length;
    data_all = [zeros(num_zero_fill,1); data_all];
end

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
    
    if i > frame_start-1
        saved_file_name = strcat(file_location,num2str(i-1,'%03d'),'.mat')
        eval(['save(saved_file_name,''Xcube_chirp_all_antena'',''-v6'');']);
    end
end