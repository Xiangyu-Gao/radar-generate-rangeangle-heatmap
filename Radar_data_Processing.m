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
Tc = 120e-6; %us
fft_Rang = 400; % 400=>384
fft_Vel = 256;
fft_Ang = 384;
num_crop = 8;
max_value = 5e+03;

% Creat grid table
freq_res = Fs/fft_Rang;% range_grid
freq_grid = (0:fft_Rang-1).'*freq_res;
rng_grid = freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;

w = [-180:4:180]; % angle_grid
agl_grid = asin(w/180)*180/pi; % [-1,1]->[-pi/2,pi/2]

% velocity_grid
dop_grid = fftshiftfreqgrid(fft_Vel,1/Tc); % now fs is equal to 1/Tc
vel_grid = dop_grid*lambda/2;   % unit: m/s, v = lamda/4*[-fs,fs], dopgrid = [-fs/2,fs/2]


% Algorithm parameters
frame_start = 1;
frame_end = 900;
option = 0; % option=0,only plot ang-range; option=1, 
% option=2,only record raw data in format of matrix; option=3,ran+dop+angle estimate;
IS_Plot_RD = 0; % 1 ==> plot the Range-Doppler heatmap
IS_SAVE_Data = 1;% 1 ==> save range-angle data and heatmap figure
Is_Det_Static = 1;% 1==> detection includes static objects (!!! MUST BE 1 WHEN OPYION = 1)
Is_Windowed = 1;% 1==> Windowing before doing range and angle fft
num_stored_figs = 900;% the number of figures that are going to be stored

%% file information
capture_date_list = ["2019_04_09"];

for ida = 1:length(capture_date_list)
capture_date = capture_date_list(ida);
folder_location = strcat('F:/RawData/', capture_date, '/');
files = dir(folder_location); % find all the files under the folder
n_files = length(files);

% processed_files = [3:7,9:14,16:21] %0430
% processed_files = [3:7,9:14,16:21] %0430
% processed_files = [3:5,7:16] %0509
% processed_files = [3:n_files] %0528 
% processed_files = [3:n_files] %0529
if contains(capture_date, '04_09')
    processed_files = [3:14,18] %0409
elseif contains(capture_date, '04_30')
    processed_files = [3:7,9:14,16:21] %0430
elseif contains(capture_date, '05_09')
    processed_files = [3:5,7:16] %0509
else
    processed_files = [3:n_files] %0529,0529,0523
end

for index = 1:length(processed_files)
    inum = processed_files(index);
    file_name = files(inum).name;
    % generate file name and folder
    file_location = strcat(folder_location,'/',file_name,'/rad_reo_zerf/');
    for ign = 1:1
        if option == 0 && Is_Windowed == 0
            saved_folder_name = strcat('F:/Processed_data/UNWINDOWED/',capture_date,'/',file_name);
            saved_fig_folder_name = strcat('F:/RADAR HEATMAP FIGURE/UNWINDOWED/',capture_date,'/',file_name);
        elseif option == 0 && Is_Windowed == 1
            saved_folder_name = strcat('F:/Processed_data/WINDOWED/',capture_date,'/',file_name,'/DATA');
            saved_fig_folder_name = strcat('F:/RADAR HEATMAP FIGURE/WINDOWED/',capture_date,'/',file_name);
        else
        end
        
        if ~exist(saved_folder_name, 'dir') % check the folder exist
            mkdir(saved_folder_name);
        end
        if ~exist(saved_fig_folder_name, 'dir') % check the folder exist
            mkdir(saved_fig_folder_name);
        end
    end
    
    %% read the data file
    data = readDCA1000(file_location, samples);
    data_length = length(data);
    data_each_frame = samples*loop*Tx;
    Frame_num = data_length/data_each_frame;
    
    % check whether Frame number is an integer
    if Frame_num == 900
        frame_end = Frame_num;
    elseif abs(Frame_num - 900) < 30
        fprintf('Error! Frame is not complete')
        frame_start = 900 - fix(Frame_num) + 1;
        % zero fill the data
        num_zerochirp_fill = 900*data_each_frame - data_length;
        data = [zeros(4,num_zerochirp_fill), data];
    elseif abs(Frame_num - 900) >= 30 && Frame_num == fix(Frame_num)
        frame_end = Frame_num;
    else
    end
    
    caliDcRange_odd = [];
    caliDcRange_even = [];
    
    for i = frame_start:frame_end
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
            
            % Check whether to plot range-doppler heatmap
            if IS_Plot_RD
                % Doppler FFT
                [Dopdata_odd] = fft_doppler(Rangedata_odd,fft_Vel);
                % plot range-doppler
                plot_rangeDop(Dopdata_odd,vel_grid,rng_grid)
            else
                
            end
            
            % FOR CHIRP 2
            % Range FFT
            [Rangedata_even] = fft_range(chirp_even,fft_Rang,Is_Windowed);
            
            % Angle FFT
            % need to do doppler compensation on Rangedata_chirp2 in future
            Rangedata_merge = [Rangedata_odd,Rangedata_even];
            Angdata = fft_angle(Rangedata_merge,fft_Ang,Is_Windowed);
            Angdata_crop = Angdata(num_crop + 1:fft_Rang - num_crop,:,:);
            [Angdata_crop] = Normalize(Angdata_crop, max_value);
            
            if i < frame_start + num_stored_figs % plot Range_Angle heatmap
                [axh] = plot_rangeAng(Angdata_crop, ...
                    rng_grid(num_crop + 1:fft_Rang - num_crop),agl_grid);
            end
            
            if IS_SAVE_Data
                % save range-angle heatmap to .mat file
                saved_file_name = strcat(saved_folder_name,'/',file_name,'_',num2str(i-1,'%06d'),'.mat');
                save(saved_file_name,'Angdata_crop','-v6');
                
                if i < frame_start + num_stored_figs % plot rectangle
%                     posiObjCam = [agl_grid(cur_pos(2))-widthRec/2,rng_grid(cur_pos(1))-heigtRec/2];
%                     hold on
%                     plot_rectangle(posiObjCam,widthRec,heigtRec);
                    % save to figure
                    saved_fig_file_name = strcat(saved_fig_folder_name,'/','frame_',num2str(i-1,'%06d'),'.png');
                    saveas(axh,saved_fig_file_name,'png');
                    close
                end
            end
            i % print index i
        elseif option == 1
            
        elseif option == 2
            %% record raw data in the form of matrix
            for ir = 1:1
                if i > frame_start-1
                    saved_file_name = strcat(file_name,'_',num2str(i,'%03d'),'.mat');
                    Xcube_chirp = [Xcube_chirp1,Xcube_chirp2];
                    eval(['save(saved_file_name,''Xcube_chirp'',''-v6'');']);
                else
                end
            end
        elseif option == 3
            %% ran+dop+angle estimate
            for ie = 1:1
                % chirp1
                % range fft
                [Rangedata_chirp1]=range_fft(Xcube_chirp1,fft_Rang,fft_Vel,fft_Ang);
                
                % caliDcRangeSig
                for anti = 1:4
                    if rem(i,20) == 1
                        caliDcRange(:,anti) = sum(squeeze(Rangedata_chirp1(:,anti,:)),2)/loop;
                    else
                    end
                    % remove DC
                    Rangedata_chirp1(1:3,anti,:) = Rangedata_chirp1(1:3,anti,:) - repmat(caliDcRange(1:3,anti),...
                        1,size(Rangedata_chirp1(1:3,anti,:),2),size(Rangedata_chirp1(1:3,anti,:),3));
                end
                
                % doppler fft
                Dopdata_chirp1 = doppler_fft(Rangedata_chirp1,fft_Rang,fft_Vel,fft_Ang);
                figure()
                mesh(vel_grid,rng_grid,abs(squeeze(Dopdata_chirp1(:,1,:))));
                view(0,90)
                axis([-10,10,0,25])
                title('Range-doppler plot for Rx1')
                xlabel('doppler')
                ylabel('Range')
                
                %for chirp2
                [Rangedata_chirp2]=range_fft(Xcube_chirp2,fft_Rang,fft_Vel,fft_Ang);
                
                % caliDcRangeSig
                for anti = 1:4
                    if rem(i,20) == 1
                        caliDcRange(:,anti) = sum(squeeze(Rangedata_chirp2(:,anti,:)),2)/loop;
                    else
                    end
                    % remove DC
                    Rangedata_chirp2(1:3,anti,:) = Rangedata_chirp2(1:3,anti,:) - repmat(caliDcRange(1:3,anti),...
                        1,size(Rangedata_chirp2(1:3,anti,:),2),size(Rangedata_chirp2(1:3,anti,:),3));
                end
                
                % doppler fft
                Dopdata_chirp2 = doppler_fft(Rangedata_chirp2,fft_Rang,fft_Vel,fft_Ang);
                % sum
                Dopdata_sum = squeeze(sum(abs(Dopdata_chirp1)+abs(Dopdata_chirp2),2))/8;
                
                for rani = 4:fft_Rang     %%% from range 4(because the DC component in range1-3 have been canceled)
                    x_detected = cfar_ca1D(Dopdata_sum(rani,:),4,3,4,1);
                    x_dop = [x_dop,x_detected];
                end
                
                % make unique
                [C,~,~] = unique(x_dop(1,:));
                
                % CFAR for each specific doppler bin
                for dopi = 1:size(C,2)
                    y_detected = cfar_ca1D(Dopdata_sum(:,C(1,dopi)),4,4,3,0);
                    if isempty(y_detected) ~= 1
                        Resl_indx_temp = [C(1,dopi)*ones(1,size(y_detected,2));y_detected];%%% 1st doppler, 2st range, 3st object power(log2), 4th estimated noise
                        Resl_indx = [Resl_indx,Resl_indx_temp];
                    else
                        
                    end
                end
                
                % delete the nodes which has -inf noiseSum
                Resl_indx(:,isinf(Resl_indx(4,:))) = [];
                
                % Angle FFT
                for angi = 1:size(Resl_indx,2)
                    Dop_Antedata = [Dopdata_chirp1(Resl_indx(2,angi),:,Resl_indx(1,angi)),Dopdata_chirp2(Resl_indx(2,angi),:,Resl_indx(1,angi))];
                    Angdata = angFFT(Dop_Antedata,fft_Ang);
                    [~,I]=max(abs(Angdata));
                    Resl_indx(5,angi) = I;
                end
            end
        else
            
        end
    end
    
end
end
