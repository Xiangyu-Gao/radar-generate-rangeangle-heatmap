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
set_frame_number = 900;
Tc = 120e-6; % us
fft_Rang = 134;
fft_Vel = 256;
fft_Ang = 128;
num_crop = 3;
max_value = 1e+04; % data WITH 1843

Pfa = 1e-5;

% Creat grid table
freq_res = Fs/fft_Rang;% range_grid
freq_grid = (0:fft_Rang-1).'*freq_res;
rng_grid = freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;
rng_grid = rng_grid(4:fft_Rang-3); % crop rag_grid

w = linspace(-1,1,fft_Ang); % angle_grid
agl_grid = asin(w)*180/pi; % [-1,1]->[-pi/2,pi/2]

dop_grid = fftshiftfreqgrid(fft_Vel,1/Tc); % velocity_grid, now fs is equal to 1/Tc
vel_grid = dop_grid*lambda/2;   % unit: m/s, v = lamda/4*[-fs,fs], dopgrid = [-fs/2,fs/2]


% Algorithm parameters
frame_start = 1;
frame_end = set_frame_number;
option = 0; % option=0,only plot ang-range; option=1,
% option=2,only record raw data in format of matrix; option=3,ran+dop+angle estimate;
IS_Plot_RD = 0; % 1 ==> plot the Range-Doppler heatmap
IS_SAVE_Data = 1;% 1 ==> save range-angle data and heatmap figure
Is_Det_Static = 1;% 1==> detection includes static objects (!!! MUST BE 1 WHEN OPYION = 1)
Is_Windowed = 1;% 1==> Windowing before doing range and angle fft
num_stored_figs = set_frame_number;% the number of figures that are going to be stored

%% file information
capture_date_list = ["2019_05_23", "2019_05_28", "2019_05_29"];

for ida = 1:length(capture_date_list)
    capture_date = capture_date_list(ida);
    folder_location = strcat('/mnt/nas_crdataset/', capture_date, '/');
    files = dir(folder_location); % find all the files under the folder
    n_files = length(files);
    
    processed_files = [3:n_files]
    
%     if contains(capture_date, '04_09')
%         processed_files = [3:14,18] %0409
%     elseif contains(capture_date, '04_30')
%         processed_files = [3:7,9:14,16:21] %0430
%     elseif contains(capture_date, '05_09')
%         processed_files = [3:5,7:16] %0509
%     else
%         processed_files = [3:n_files] %0529,0529,0523
%     end
    
    for index = 1:length(processed_files)
        inum = processed_files(index);
        file_name = files(inum).name;
        % generate file name and folder
        file_location = strcat(folder_location,file_name,'/rad_reo_zerf/');
        
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
        elseif abs(Frame_num - set_frame_number) >= 30 && Frame_num == ...
                fix(Frame_num)
            frame_end = Frame_num;
        else
        end
        
        
        
        for i = frame_start:frame_end
            x_dop = [];
            Resl_indx = [];
            % reshape data of each frame to the format [samples, Rx, chirp]
            data_frame = data(:,(i-1)*data_each_frame+1:i*data_each_frame);
            data_chirp = [];
            for cj=1:Tx*loop
                temp_data = data_frame(:,(cj-1)*samples+1:cj*samples);
                data_chirp(:,:,cj) = temp_data;
            end
            chirp_odd = data_chirp(:,:,1:2:end);
            chirp_even = data_chirp(:,:,2:2:end);
            chirp_odd = permute(chirp_odd, [2,1,3]);
            chirp_even = permute(chirp_even, [2,1,3]);
            
            if option == 0
                %% plot ang-range and find the location of objects
                % FOR CHIRP 1
                % Range FFT
                [Rangedata_odd] = fft_range(chirp_odd,fft_Rang,Is_Windowed);
                
                % FOR CHIRP 2
                % Range FFT
                [Rangedata_even] = fft_range(chirp_even,fft_Rang,Is_Windowed);
                
                % Check whether to plot range-doppler heatmap
                % Velocity FFT
                
                % Doppler FFT
                [Dopdata_odd] = fft_doppler(Rangedata_odd,fft_Vel,Is_Windowed);
                [Dopdata_even] = fft_doppler(Rangedata_even,fft_Vel,Is_Windowed);
                %                     % plot range-doppler image
                %                     plot_rangeDop(Dopdata_odd,vel_grid,rng_grid)
                
                
                % sum up the amplitude of all RV heatmaps
                Dopdata_sum = squeeze(sum(abs(Dopdata_odd),2) + ...
                    sum(abs(Dopdata_even),2)) ;
                % Normalize
                Dopdata_sum = Dopdata_sum/max_value;
                
                for rani = num_crop+1:fft_Rang-num_crop
                    % from range 4(because the DC component in range1-3 
                    % have been canceled)
                    x_detected = cfar_ca1D_square(Dopdata_sum(rani,:),4,3,Pfa,1);
                    x_dop = [x_dop,x_detected];
                end
                
                % make unique
                [C,~,~] = unique(x_dop(1,:));
                
                % CFAR for each specific doppler bin
                for dopi = 1:size(C,2)
                    y_detected = cfar_ca1D_square(Dopdata_sum(:,C(1,dopi)), ...
                        4,4,Pfa,0);
                    if isempty(y_detected) ~= 1
                        Resl_indx_temp = [C(1,dopi)*ones(1,size(y_detected,2)); ...
                            y_detected];
                        % 1st doppler, 2st range, 3st object power square), ...
                        % 4th estimated noise
                        Resl_indx = [Resl_indx,Resl_indx_temp];
                    else
                        
                    end
                end
                
                if isempty(Resl_indx) ~= 1
                    % delete the nodes which has -inf noiseSum
                    Resl_indx(:,isinf(Resl_indx(4,:))) = [];
                    % delete the nodes in crop-range
                    Resl_indx(:,find(Resl_indx(2,:) > fft_Rang - num_crop)) = [];
                    Resl_indx(:,find(Resl_indx(2,:) < num_crop + 1)) = [];
                end
                
                if isempty(Resl_indx) ~= 1
                    
                    % peak grouping in Range-Velocity domain
                    [new_detect] = peakGrouping(Resl_indx);
                    
                    % Angle FFT
                    Dopdata_merge = [Dopdata_odd, Dopdata_even];
                    for di = 1:size(new_detect,2)
                        new_ran_idx = new_detect(2,di);
                        new_dop_idx = new_detect(1,di);
                        Angdata = fft_angle(Dopdata_merge(new_ran_idx,:, ...
                            new_dop_idx),...
                            64,Is_Windowed);
                        [~, agl_index] = max(Angdata);
                        new_detect(4,di) = agl_index; % Angle index
                    end
                    
                    new_detect([1 4],:) = new_detect([4 1],:);
                    % peak grouping in Range-Angle domain
                    [nnew_detect] = peakGrouping(new_detect);
                    % permute back
                    nnew_detect([1 4],:) = nnew_detect([4 1],:);
                    % Angle FFT again
                    for di = 1:size(nnew_detect,2)
                        new_ran_idx = nnew_detect(2,di);
                        new_dop_idx = nnew_detect(1,di);
                        Angdata = fft_angle(Dopdata_merge(new_ran_idx,:, ...
                            new_dop_idx), ...
                            fft_Ang,Is_Windowed);
                        [~, agl_index] = max(Angdata);
                        nnew_detect(4,di) = agl_index; % Angle index
                    end
                    
                    % permute again
                    nnew_detect([3 4],:) = nnew_detect([4 3],:);
                    
                    if IS_SAVE_Data
                        txt_name = strcat(file_name, '.txt');
                        fileID = fopen(txt_name,'a');
                        for ndi = 1:size(nnew_detect,2)
                            % 1,doppler 2,range 3,angle 4, amplit
                            fprintf(fileID,'%d %d %d %d %f\n',i, nnew_detect(1,ndi), ...
                                nnew_detect(2,ndi), nnew_detect(3,ndi), nnew_detect(4,ndi));
                        end
                        fclose(fileID);
                    end
                end
                i % print index i
            else
                
            end
        end
        clear data
    end
end
