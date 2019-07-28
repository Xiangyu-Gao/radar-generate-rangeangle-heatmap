%%% This script is to post-Process ADC capture data from TSW1400 using HSDC-pro %%%
%%% Command to run in Matlab GUI - read_Post_process_ADC_Capture_data_LVDS('<ADC capture bin file>', '<profile Type>')
%%% 
%%% as   >> Post_process_ADC_Capture_data_LVDS('D:\Auto_Radar\ADC Temp.bin', 'A')

function [retval] = read_Post_process_ADC_Capture_data_LVDS(fname, Config)

% you provide the path and filename
fname = 'C:\ti\mmwave_dfp_00_07_00_04\rf_eval\radarstudio\PostProc\adc_data.bin';               % radar studio 
fname = 'C:\Program Files (x86)\Texas Instruments\High Speed Data Converter Pro\ADC Temp.bin';   % tsw1400 hsdPro 

% enter chirp parameters here, you can modify the default, and select or modify the Config set (Configs A-G are predefined)
Config = 'F';

% default setting, if Config is outside A - G
slope_Hz_per_sec = 67e12;% 
sampling_rate_Sps = 30.0e6;
n_adc_samples = 900;
n_chirps = 128;
n_adc_bits = 16;  %%%%%%%% Change this to 12/16 based on what is ADC bit set in device %%%%
n_rx = 4;
n_tx = 3;
isreal = 0; 

% start of code
lightSpeed_meters_per_sec = 3e8;
norm_factor = (sqrt(2)/(2^(n_adc_bits-1)-1));

if Config == 'A'
    n_tx = 1; 
    n_rx = 4; 
    n_adc_samples = 100; 
    sampling_rate_Sps = 10e6;
    slope_Hz_per_sec = 10e12;
    n_chirps = 128;
    isreal = 0; 
elseif Config == 'B'
    n_tx = 1; 
    n_rx = 4; 
    sampling_rate_Sps = 20e6;
    n_adc_samples = 400; 
    slope_Hz_per_sec = 10e12;
    n_chirps = 128;
    isreal = 1;
elseif Config == 'C'
    n_tx = 1; 
    n_rx = 4; 
    sampling_rate_Sps = 30e6;
    n_adc_samples = 900; 
    slope_Hz_per_sec = 10e12;
    n_chirps = 128;
    isreal = 1;
elseif Config == 'D'
    n_tx = 2; %1,2
    n_rx = 4; 
    sampling_rate_Sps = 10e6;
    n_adc_samples = 200; 
    slope_Hz_per_sec = 5e12;
    n_chirps = 128;
    isreal = 0;
elseif Config == 'E'
    n_tx = 3; %1,2,3 
    n_rx = 4; 
    n_adc_samples = 200; 
    sampling_rate_Sps = 10e6;
    slope_Hz_per_sec = 5e12;
    n_chirps = 128;
    isreal = 0; 
elseif Config == 'F'
    n_tx = 1; 
    n_rx = 4; 
    n_adc_samples = 896; 
    sampling_rate_Sps = 30e6;
    slope_Hz_per_sec = 67e12;
    n_chirps = 128;
    isreal = 1; 
elseif Config == 'G'
    n_tx = 3;  %1,2,3,
    n_rx = 4; 
    n_adc_samples = 896; 
    sampling_rate_Sps = 30e6;
    slope_Hz_per_sec = 67e12;
    n_chirps = 128 ; 
    isreal = 1; 
end

fid = fopen(fname,'r');

if isreal
    dat = fread(fid,n_adc_samples*n_chirps*n_rx*n_tx,'uint16');
    dat = dat - 2^15;  % needs to be checked if 12 or 14bit data is used
    
    dat = reshape(dat,8,[]); 
    dat = dat([1,3,5,7,2,4,6,8],:);
    if n_adc_bits ~= 16
        l_max = 2^(n_adc_bits-1)-1;
        dat(dat > l_max) = dat(dat > l_max) - 2^n_adc_bits;
    end
   
    lendata = max(size(dat))
    dat = dat*norm_factor;
    radar_data_all = reshape(dat, n_adc_samples,  n_rx, n_tx, n_chirps,1);%Samples_Per_Chirp*2 for I and Q
    data_real = radar_data_all;
    cdat = data_real;
else
    dat = fread(fid,n_adc_samples*n_chirps*n_rx*n_tx*2,'uint16');
    dat = dat - 2^15;
    
    if n_adc_bits ~= 16
        l_max = 2^(n_adc_bits-1)-1;
        dat(dat > l_max) = dat(dat > l_max) - 2^n_adc_bits;
    end

    dat = reshape(dat,8,[]); 
    dat = dat([1,3,5,7,2,4,6,8],:);
    cdat = dat(1:4,:) + 1i*dat(5:8,:);
    
    cdat = cdat*norm_factor;
    
    cdat = reshape(cdat, n_adc_samples,n_rx, n_tx, n_chirps,1);%Samples_Per_Chirp*2 for I and Q
    
end
fclose(fid);
pre_adc_dat = (cdat);
    

x_axis = ((((0:n_adc_samples-1)/n_adc_samples)*sampling_rate_Sps)/slope_Hz_per_sec)*lightSpeed_meters_per_sec/2;

hann_win = hanning(size(pre_adc_dat(:,1,1,1),1));

% Normalize for window, and for 2D FFT gain.
hann_win = hann_win/sum(hann_win)/n_chirps;

for ik = 1:n_chirps
    for rx_indx = 1:n_rx
        for tx_indx = 1:n_tx
            adc_dat(:,rx_indx,tx_indx,ik) = hann_win.*(pre_adc_dat(:,rx_indx,tx_indx,ik));
        end
    end
end

%% Plots. 

%% 1. 2D-FFT plot consisting of only the zero-velocity bin, and the noise floor. 
%     The noise floor is an average of multiple high velocity bins.
%     The data from all tx-rx combinations are seperately plotted.
figure(123);
hold off;
marker = '';
color = 'br';

for rx_indx = 1:n_rx
    for tx_indx = 1:n_tx
        subplot(n_rx,n_tx,tx_indx + (rx_indx-1)*n_tx);
        fft2_out{rx_indx} = abs(fft2(squeeze(adc_dat(:,rx_indx, tx_indx,:))));
        if rx_indx == 1 && tx_indx == 1
            fft2_out_all = (fft2_out{rx_indx}.*fft2_out{rx_indx}); 
        else
            fft2_out_all = fft2_out_all  +  (fft2_out{rx_indx}.*fft2_out{rx_indx}); 
        end

        plot(x_axis, 20*log10(fft2_out{rx_indx}(:,1)),[color(1) '-' marker]); hold on;
        plot(x_axis, 20*log10(rms(fft2_out{rx_indx}(:,64-32:64+32),2)),[color(2) '-' marker]);
        xlabel('Range (meters)');
        ylabel('FFT Output (dBFs)');
        if rx_indx == n_rx && tx_indx == n_tx
            legend (['0-doppler bins' ], ['Noise floor']);
        end
        title(['Tx : ' num2str(tx_indx) ',' 'Rx : ' num2str(rx_indx) '.'])
        grid minor;        %view([0 0])
    end
end

%% 2. 2D-FFT plot mesh-plot. 
%     The data from all tx-rx combinations are non-coherently integrated.

figure(124);
fft2_out_all = fft2_out_all/n_rx;
imagesc(1:128,x_axis,10*log10(fftshift(fft2_out_all,2)));
title(['2D FFT (non-coherently integrated).']);
figure(125);

%% 3. 1D-FFT plot averaged across all chirps in a frame. 
%     The data from all tx-rx combinations are seperately plotted.

for rx_indx = 1:n_rx
    for tx_indx = 1:n_tx
        subplot(n_rx,n_tx,tx_indx + (rx_indx-1)*n_tx);

        fft_out_tmp = abs(fft(squeeze(adc_dat(:,rx_indx,tx_indx,:)),[],1)); 
        fft_out_tmp = mean(fft_out_tmp.*fft_out_tmp,2);
        fft2_out{rx_indx} = 10*log10(fft_out_tmp);
        plot(x_axis, fft2_out{rx_indx},[color(1) '-' marker]); hold on; 
        xlabel('Range (meters)');
        ylabel('FFT Output (dBFs)');
        title(['Tx : ' num2str(tx_indx) ',' 'Rx : ' num2str(rx_indx) '.'])
    end
end

figure(126);
%% 4. ADC data plot. 
%     data from all chirps are plotted on top of each other. 
%     data from all tx-rx combinations are seperately plotted.

for rx_indx = 1:n_rx
    for tx_indx = 1:n_tx
        subplot(n_rx,n_tx,tx_indx + (rx_indx-1)*n_tx);

        x_axis_samples = 1:n_adc_samples;
        plot(x_axis_samples, real((squeeze(pre_adc_dat(:,rx_indx,tx_indx,1)/norm_factor))),['r-' marker]); hold on;
        if isreal == 0
            plot(x_axis_samples, imag((squeeze(pre_adc_dat(:,rx_indx,tx_indx,1)/norm_factor))),['b-' marker]); hold on;
        end
        xlabel('sample number');
        ylabel('ADC codewords');
        title(['Tx : ' num2str(tx_indx) ',' 'Rx : ' num2str(rx_indx) '.']);
        grid minor;     
        if isreal == 0 && rx_indx == n_rx && tx_indx == n_tx
            legend (['Real ' ], ['Imag ']);
        end
    end
end

end
