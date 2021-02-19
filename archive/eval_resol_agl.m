clc;
clear all;
close all;
%% parameter setting
% constant parameters
c = physconst('LightSpeed');% Speed of light in air (m/s)
fc = 77e9; % Center frequency (Hz)
lambda = c/fc;
Rx = 4;
Tx = 2;

% configuration parameters
Fs = 4*10^6;
sweepSlope = 21.0017e12;
samples = 128;
loop = 255;
set_frame_number = 10;
Tc = 90e-6; %us % previous 120us
fft_Rang = 134; % 134=>128
fft_Vel = 256;
fft_Ang = 128;
num_crop = 3;
max_value = 4e+04; % data WITH 1843

% Creat grid table
freq_res = Fs/fft_Rang;% range_grid
freq_grid = (0:fft_Rang-1).'*freq_res;
rng_grid = freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;

w = linspace(-1,1,fft_Ang); % angle_grid
agl_grid = asin(w)*180/pi; % [-1,1]->[-pi/2,pi/2]

% velocity_grid
dop_grid = fftshiftfreqgrid(fft_Vel,1/Tc); % now fs is equal to 1/Tc
vel_grid = dop_grid*lambda/2;   % unit: m/s, v = lamda/4*[-fs,fs], dopgrid = [-fs/2,fs/2]


% Algorithm parameters
frame_start = 1;
frame_end = set_frame_number;
option = 0; % option=0,only plot ang-range; option=1,
% option=2,only record raw data in format of matrix; option=3,ran+dop+angle estimate;
IS_Plot_RD = 0; % 1 ==> plot the Range-Doppler heatmap
IS_SAVE_Data = 0;% 1 ==> save range-angle data and heatmap figure
Is_Det_Static = 1;% 1==> detection includes static objects (!!! MUST BE 1 WHEN OPYION = 1)
Is_Windowed = 1;% 1==> Windowing before doing range and angle fft
num_stored_figs = set_frame_number;% the number of figures that are going to be stored
Is_Plot_Aglprof = 1; %1==> Ploting the angle profile at the maximum reflection range
%% file information
% generate file name and folder
file_location = '/home/admin-cmmb/Documents/MATLAB/radar-generate-rangeangle-heatmap/test_data';



%% read the data file
data = readDCA1000(file_location, samples);
data_length = length(data);
data_each_frame = samples*loop*Tx;
Frame_num = data_length/data_each_frame;

% check whether Frame number is an integer
if Frame_num == set_frame_number
    frame_end = Frame_num;
elseif abs(Frame_num - set_frame_number) < 30
    fprintf('Error! Frame is not complete')
    frame_start = set_frame_number - fix(Frame_num) + 1;
    % zero fill the data
    num_zerochirp_fill = set_frame_number*data_each_frame - data_length;
    data = [zeros(4,num_zerochirp_fill), data];
elseif abs(Frame_num - set_frame_number) >= 30 && Frame_num == fix(Frame_num)
    frame_end = Frame_num;
else
end

caliDcRange_odd = [];
caliDcRange_even = [];

for i = frame_start:5
    % reshape data of each frame to the format [samples, Rx, chirp]
    data_frame = data(:,(i-1)*data_each_frame+1:i*data_each_frame);
    data_chirp = [];
    for cj=1:Tx*loop
        temp_data = data_frame(:,(cj-1)*samples+1:cj*samples);
        data_chirp(:,:,cj) = temp_data;
    end
    chirp_odd_raw = data_chirp(:,:,1:2:end);
    chirp_even_raw = data_chirp(:,:,2:2:end);
    chirp_odd_raw = permute(chirp_odd_raw, [2,1,3]);
    chirp_even_raw = permute(chirp_even_raw, [2,1,3]);
    
%     % decode BPM
%     for decode_i = 1:4
%         for decode_j = 1:255
%             chirp_odd(:,decode_i,decode_j) = (chirp_odd_raw(:,decode_i,decode_j) + chirp_even_raw(:,decode_i,decode_j))/2;
%             chirp_even(:,decode_i,decode_j) = (chirp_odd_raw(:,decode_i,decode_j) - chirp_even_raw(:,decode_i,decode_j))/2;
%         end
%     end

    chirp_odd = chirp_odd_raw;
    chirp_even = chirp_even_raw;
    
    if option == 0
        %% plot ang-range and find the location of objects
        % FOR CHIRP 1
        % Range FFT
        [Rangedata_odd] = fft_range(chirp_odd,fft_Rang,Is_Windowed);
        % FOR CHIRP 2
        % Range FFT
        [Rangedata_even] = fft_range(chirp_even,fft_Rang,Is_Windowed);
%         figure()
%         plot(rng_grid(5:25), sum(abs(Rangedata_odd(5:25,1,:)),3)/255)
        
        % Check whether to plot range-doppler heatmap
        if IS_Plot_RD
            % Doppler FFT
            [Dopdata_odd] = fft_doppler(Rangedata_odd,fft_Vel, Is_Windowed);
            % plot range-doppler
            plot_rangeDop(Dopdata_odd,vel_grid,rng_grid)
        else
            
        end
        
        
        % Angle FFT
        % need to do doppler compensation on Rangedata_chirp2 in future
        Rangedata_merge = [Rangedata_odd, Rangedata_even];
%         Rangedata_merge = Rangedata_odd;
        Angdata = fft_angle(Rangedata_merge,fft_Ang,Is_Windowed);
        Angdata_crop = Angdata(num_crop + 1:fft_Rang - num_crop,:,:);
        [Angdata_crop] = Normalize(Angdata_crop, max_value);
        
        if i < frame_start + num_stored_figs % plot Range_Angle heatmap
            [axh] = plot_rangeAng(Angdata_crop, ...
                rng_grid(num_crop + 1:fft_Rang - num_crop), agl_grid);
        end
        
        if Is_Plot_Aglprof
            % find the maximum reflection range
            [maxv, maxI] = max(sum(abs(Rangedata_odd), [2,3]));
            figure()
            plot(agl_grid, mean(abs(Angdata_crop(maxI-3, :, :)), 3));
            xlabel('Angle of arrive(degrees)')
            ylabel('Amplitude')
            axis([-60 60 0 1.2]);
            title('Azimuth Profile')
        end
        
        if IS_SAVE_Data
            % save range-angle heatmap to .mat file
            saved_file_name = strcat(saved_folder_name,'/', ...
                file_name,'_',num2str(i-1,'%06d'),'.mat');
            save(saved_file_name,'Angdata_crop','-v6');
            
            if i < frame_start + num_stored_figs % plot rectangle
                % save to figure
                saved_fig_file_name = strcat(saved_fig_folder_name, ...
                    '/','frame_',num2str(i-1,'%06d'),'.png');
                saveas(axh,saved_fig_file_name,'png');
                close
            end
        end
        i % print index i
    elseif option == 1
        
    else
        
    end
end
clear data


