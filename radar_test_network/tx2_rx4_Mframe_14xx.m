clc;
clear all;
close all;
%% parameter setting
fc = 78.5e9;                                  % Center frequency (Hz)
Fs=10^7;
sweepSlope=49.9700e12;                      
samples=256;
loop=128;
Frame_num=40;
% Frame_num=20;
Rx=4;
Tx=2;

fft_Rang=256;
fft_Vel=128;
fft_Ang=181;
% read the data file
for k=1:1 %IMPORTANT!!
    %% data analysis
    eval(['data=readTSW14xx','(''C:\Users\Administrator\Desktop\UW\testData\test_11_7\',int2str(k),'.bin'');']);
%     eval(['data=readDCA14xx','(''C:\ti\mmwave_studio_01_00_00_00\mmWaveStudio\PostProc\adc_data1.bin'');']);
    
    data_length=length(data);
    data_each_frame=data_length/Frame_num;
    data_all=reshape(data',size(data,1)*size(data,2),[]);  %%%%reshape 4 channels into 1
    Y1 = [];
    caliDcRange = [];
    for i=1:1
        Framedata(:,:,i)=data(:,((i-1)*data_each_frame+1):i*data_each_frame);
        Frame(:,i)=reshape(Framedata(:,:,i).',size(Framedata(:,:,i),1)*size(Framedata(:,:,i),2),[]);  %%%%reshape 4 channels into 1
        Frame_loop(:,:,i)=reshape(Frame(:,i),samples,[]);
        Frame_loop_chirp1(:,:,i)=Frame_loop(:,1:2:end,i);
        Frame_loop_chirp2(:,:,i)=Frame_loop(:,2:2:end,i);
        
        Frame_loop_chirp1_Rx(:,:,:,i)=reshape(Frame_loop_chirp1(:,:,i),[samples loop Rx]);
        Frame_loop_chirp2_Rx(:,:,:,i)=reshape(Frame_loop_chirp2(:,:,i),[samples loop Rx]);
        %     load('Xcube.mat')
        Xcube_chirp1=permute(Frame_loop_chirp1_Rx(:,:,:,i),[1 3 2]);
        Xcube_chirp2=permute(Frame_loop_chirp2_Rx(:,:,:,i),[1 3 2]);
        %% for chirp1
        [Rangedata_chirp1,Dopdata_chirp1,Angdata_chirp1]=fft_Radar(Xcube_chirp1,fft_Rang,fft_Vel,fft_Ang);
        
        % caliDcRangeSig
        if rem(i,20) == 1
            caliDcRange = sum(squeeze(Rangedata_chirp1(:,1,:)),2)/loop;
        else
        end
        Rangedata_chirp1(128:130,:,:) = Rangedata_chirp1(128:130,:,:) - repmat(caliDcRange(128:130,1),...
            1,size(Rangedata_chirp1(128:130,:,:),2),size(Rangedata_chirp1(128:130,:,:),3));
        
        figure()
        mesh([1:128],[1:256],abs(squeeze(Dopdata_chirp1(:,1,:))));
        title('Range-doppler plot for Rx1')
        plot_rangeAng(Angdata_chirp1,fc,Fs,sweepSlope);
        title('Range-angle plot with signal Tx')
       %% for chirp2
        [Rangedata_chirp2,Dopdata_chirp2,Angdata_chirp2]=fft_Radar(Xcube_chirp2,fft_Rang,fft_Vel,fft_Ang);
        % caliDcRangeSig
        if rem(i,20) == 1
            caliDcRange = sum(squeeze(Rangedata_chirp2(:,1,:)),2)/loop;
        else
        end
        Rangedata_chirp2(128:130,:,:) = Rangedata_chirp2(128:130,:,:) - repmat(caliDcRange(128:130,1),...
            1,size(Rangedata_chirp2(128:130,:,:),2),size(Rangedata_chirp2(128:130,:,:),3));
 
       %% Angle FFT
        Rangedata = [Rangedata_chirp1,Rangedata_chirp2];
        Angdata = angFFT(Rangedata,fft_Ang);
       %% plot
        plot_rangeAng(Angdata,fc,Fs,sweepSlope);
        title('Range-angle plot with 2Tx')
    end 
end
