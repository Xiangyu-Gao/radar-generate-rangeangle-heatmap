% clc;
% clear all;
% close all;
% %% parameter setting
% % constant parameters
% c = physconst('LightSpeed');% Speed of light in air (m/s)
% fc = 77e9;% Center frequency (Hz)
% lambda = c/fc;
% Rx = 4;
% Tx = 2;
% 
% % configuration parameters
% Fs = 4*10^6;
% sweepSlope = 21.002e12;
% samples = 128;
% loop = 255;
% Tc = 60e-6; %us
% fft_Rang = 128;
% fft_Vel = 256;
% fft_Ang = 91;
% 
% % size of bounding box
% widthRec = 22.5;% degrees ==> pi/8
% heigtRec = 2.5;% meters
% 
% % Creat grid table
% for ig = 1:1
%     freq_res = Fs/fft_Rang;% range_grid
%     freq_grid = (0:fft_Rang-1).'*freq_res;
%     rng_grid = freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;
%     
%     w = [-180:4:180]; % angle_grid
%     agl_grid = asin(w/180)*180/pi; % [-1,1]->[-pi/2,pi/2]
%     
%     % velocity_grid
%     dop_grid = fftshiftfreqgrid(fft_Vel,1/Tc); % now fs is equal to 1/Tc
%     vel_grid = dop_grid*lambda/2;   % unit: m/s, v = lamda/4*[-fs,fs], dopgrid = [-fs/2,fs/2]
%     % vel_grid=3.6*vel_grid;        % unit: km/h
% end
% 
% % Algorithm parameters
% frame_start = 1;
% frame_end = 900;
% option = 0; % option=0,only plot ang-range; option=1, only generate the synthetic(merged) range-angle heatmap;
%             % option=2,only record raw data in format of matrix; option=3,ran+dop+angle estimate;
% IS_Plot_RD = 0; % 1 ==> plot the Range-Doppler heatmap 
% IS_SAVE_Data = 1;% 1 ==> save range-angle data and heatmap figure
% Is_Det_Static = 1;% 1==> detection includes static objects (!!! MUST BE 1 WHEN OPYION = 1)
% Is_Windowed = 0;% 1==> Windowing before doing angle fft
% num_stored_figs = 100;% the number of figures that are going to be stored
% cali_n = 3; % the number of range bins that need to be calibrated
% neidop_n = 3; % the number of neighbored bins around the selected the doppler 
% 
% %% file information
% capture_date = '2019_05_09';
% 
% 
% folder_location = strcat('D:/RawData/',capture_date);
% 
% files = dir(folder_location); % find all the files under the folder
% n_files = length(files);
% 
% for inum = 8:8
%     
%     file_name = files(inum).name;
%     %file_name = '2019_04_09_pms2000';
%     % generate file name and folder
%     file_location = strcat(folder_location,'/',file_name,'/rad_reo_zerf/adc_data_0.bin');
%     for ign = 1:1
%     if option == 0 && Is_Windowed == 0
%     saved_folder_name = strcat('D:/PROCESSED_RADAR_DATA/UNWINDOWED/',capture_date,'/',file_name,'/DATA');
%     saved_fig_folder_name = strcat('D:/RADAR HEATMAP FIGURE/UNWINDOWED/',capture_date,'/',file_name);
%     saved_pos_folder_name = strcat('D:/PROCESSED_RADAR_DATA/UNWINDOWED/',capture_date,'/',file_name,'/POSITION');
%     saved_pos_file_name = strcat('D:/PROCESSED_RADAR_DATA/UNWINDOWED/',capture_date,'/',file_name,'/POSITION/',file_name,'_pos.txt');
%     elseif option == 0 && Is_Windowed == 1
%     saved_folder_name = strcat('/mnt/disk1/PROCESSED_RADAR_DATA/WINDOWED/',capture_date,'/',file_name,'/DATA');
%     saved_fig_folder_name = strcat('/mnt/disk1/RADAR HEATMAP FIGURE/WINDOWED/',capture_date,'/',file_name);
%     saved_pos_folder_name = strcat('/mnt/disk1/PROCESSED_RADAR_DATA/WINDOWED/',capture_date,'/',file_name,'/POSITION');
%     saved_pos_file_name = strcat('/mnt/disk1/PROCESSED_RADAR_DATA/WINDOWED/',capture_date,'/',file_name,'/POSITION/',file_name,'_pos.txt');
%     elseif option == 1 && Is_Windowed == 0
%     saved_folder_name = strcat('/mnt/disk1/PROCESSED_RADAR_DATA/MERGED_UNWINDOWED/',capture_date,'/',file_name,'/DATA');
%     saved_fig_folder_name = strcat('/mnt/disk1/RADAR HEATMAP FIGURE/MERGED_UNWINDOWED/',capture_date,'/',file_name);
%     saved_pos_folder_name = strcat('/mnt/disk1/PROCESSED_RADAR_DATA/MERGED_UNWINDOWED/',capture_date,'/',file_name,'/POSITION');
%     saved_pos_file_name = strcat('/mnt/disk1/PROCESSED_RADAR_DATA/MERGED_UNWINDOWED/',capture_date,'/',file_name,'/POSITION/',file_name,'_pos.txt');
%     elseif option == 1 && Is_Windowed == 1
%     saved_folder_name = strcat('/mnt/disk1/PROCESSED_RADAR_DATA/MERGED_WINDOWED/',capture_date,'/',file_name,'/DATA');
%     saved_fig_folder_name = strcat('/mnt/disk1/RADAR HEATMAP FIGURE/MERGED_WINDOWED/',capture_date,'/',file_name);
%     saved_pos_folder_name = strcat('/mnt/disk1/PROCESSED_RADAR_DATA/MERGED_WINDOWED/',capture_date,'/',file_name,'/POSITION');
%     saved_pos_file_name = strcat('/mnt/disk1/PROCESSED_RADAR_DATA/MERGED_WINDOWED/',capture_date,'/',file_name,'/POSITION/',file_name,'_pos.txt');
%     end
% 
%     if ~exist(saved_folder_name, 'dir') % check the folder exist
%     mkdir(saved_folder_name);
%     end
%     if ~exist(saved_fig_folder_name, 'dir') % check the folder exist
%     mkdir(saved_fig_folder_name);
%     end
%     if ~exist(saved_pos_folder_name, 'dir') % check the folder exist
%     mkdir(saved_pos_folder_name);
%     end
%     end
% 
%     %% read the data file
%     eval(['data=readDCA16xx','(file_location);'])
%     data_all=reshape(data,size(data,1)*size(data,2),[]); % reshape 4 channels into 1
%     data_length=length(data_all);
%     data_each_frame=samples*loop*2*Rx;
%     Frame_num=data_length/data_each_frame;
%     % check whether Frame number is an integer
%     if Frame_num == 900
%         frame_start = 1;
%     else
%         
%         fprintf('Error! Frame number is not an integer')
%         frame_start = 900 - fix(Frame_num)+1;
%         % num_stored_figs = frame_end;
%         % zero fill the data_all
%         num_zero_fill = 900*data_each_frame - data_length;
%         data_all = [zeros(num_zero_fill,1); data_all];
%     end
%     
%     caliDcRange_chirp1 = [];
%     caliDcRange_chirp2 = [];
%     obj_pos = [];
%     obj_pos_value = [];
%     init_pos = [];
%     data_saved = [];
% 
%     for i=1:frame_end % 1:end frame, Note:start frame must be 1
% 
%     % seperate each frame and reshape the raw data to foramt [samples,antennas,chirps]
%     Framedata(:,i)=data_all(((i-1)*data_each_frame+1):i*data_each_frame);
%     Frame_loop(:,:,i)=reshape(Framedata(:,i),samples*4,[]);
%     Frame_loop_chirp1(:,:,i)=Frame_loop(:,1:2:end,i);
%     Frame_loop_chirp2(:,:,i)=Frame_loop(:,2:2:end,i);
%     for jj=1:loop
%     Frame_loop_chirp1_Rx(:,:,jj,i)=reshape(Frame_loop_chirp1(:,jj,i),[samples Rx]);
%     Frame_loop_chirp2_Rx(:,:,jj,i)=reshape(Frame_loop_chirp2(:,jj,i),[samples Rx]);
%     end
%     Xcube_chirp1=permute(Frame_loop_chirp1_Rx(:,:,:,i),[1 2 3]);
%     Xcube_chirp2=permute(Frame_loop_chirp2_Rx(:,:,:,i),[1 2 3]);
% 
%     %         % calculate energy (evalution)
%     %         cal_Enegry(Xcube_chirp1,Xcube_chirp2,Framedata)
%     %         plot_singnal_time(Xcube_chirp1)
% 
%     %% plot ang-range and find the location of objects
%     if i > frame_start-1
%         % FOR CHIRP 1
%         % Range FFT
%         [Rangedata_chirp1] = fft_range(Xcube_chirp1,fft_Rang);
% 
%         % caliDcRangeSig
%         [Rangedata_chirp1,caliDcRange_chirp1] = caliDcRangeSig(Rangedata_chirp1,i,loop,frame_start,caliDcRange_chirp1,cali_n);
% 
%         % Check whether to plot range-doppler heatmap
%         if IS_Plot_RD == 1
%             % Doppler FFT
%             [Dopdata_chirp1] = fft_doppler(Rangedata_chirp1,fft_Vel);
% 
%             % plot range-doppler
%             plot_rangeDop(Dopdata_chirp1,vel_grid,rng_grid)
%         else
% 
%         end
% 
%         % FOR CHIRP 2
%         % Range FFT
%         [Rangedata_chirp2] = fft_range(Xcube_chirp2,fft_Rang);
% 
%         % caliDcRangeSig
%         [Rangedata_chirp2,caliDcRange_chirp2] = caliDcRangeSig(Rangedata_chirp2,i,loop,frame_start,caliDcRange_chirp2,cali_n);
% 
%         % Angle FFT
%         % need to do doppler compensation on Rangedata_chirp2 in future
%         Rangedata_merge = [Rangedata_chirp1,Rangedata_chirp2];
%         Angdata = fft_angle(Rangedata_merge,fft_Ang,Is_Windowed);
% 
%         if i > 0
%             if i < frame_start + num_stored_figs % plot Range_Angle heatmap
%                 [axh] = plot_rangeAng(Angdata,rng_grid,agl_grid);
%             end
% 
%             if i == frame_start % search the initial position of object
%                 cur_pos = find_obj_position(Angdata,init_pos,1,Is_Det_Static);
%                 init_pos = cur_pos;
%                 obj_pos = [obj_pos;i,cur_pos]; % obj_pos list format [frame, range, angle]
%                 obj_pos_value = [obj_pos_value;i,rng_grid(cur_pos(1)),agl_grid(cur_pos(2))];
%             else % search the position of object in specific range(temporarily)
%                 cur_pos = find_obj_position(Angdata,init_pos,0,Is_Det_Static);
%                 init_pos = cur_pos;
%                 obj_pos = [obj_pos;i,cur_pos]; % obj_pos list format [frame, range, angle]
%                 obj_pos_value = [obj_pos_value;i,rng_grid(cur_pos(1)),agl_grid(cur_pos(2))];
%             end
%             
%             data_saved = [data_saved; Rangedata_merge(cur_pos(1),:,:)];
%             
%             if IS_SAVE_Data
%                 [Angdata] = Normalize(Angdata);
%                 % save range-angle heatmap to .mat file
%                 saved_file_name = strcat(saved_folder_name,'/',file_name,'_',num2str(i-1,'%06d'),'.mat');
%                 eval(['save(saved_file_name,''Angdata'',''-v6'');'])
% 
%                 if i < frame_start + num_stored_figs % plot rectangle
%                     posiObjCam = [agl_grid(cur_pos(2))-widthRec/2,rng_grid(cur_pos(1))-heigtRec/2];
%                     hold on
%                     plot_rectangle(posiObjCam,widthRec,heigtRec);
%                     % save to figure
%                     saved_fig_file_name = strcat(saved_fig_folder_name,'/','frame_',num2str(i-1,'%06d'),'.png');
%                     eval(['saveas(axh,saved_fig_file_name,''png'');'])
%                     close 
%                 end
%             end
%         i % print index i 
%         close
%         end
%     end
%     end
%     
%     saved_prepro_name = strcat(saved_folder_name,'/',file_name,'_preprocess.mat');
%     eval(['save(saved_prepro_name,''data_saved'',''-v6'');'])
%     
%     if IS_SAVE_Data
%     dlmwrite(saved_pos_file_name,obj_pos_value);
%     end
%  end


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
Tc = 120e-6; %us
fft_Rang = 128;
fft_Vel = 256;
fft_Ang = 91;

% size of bounding box
widthRec = 22.5;% degrees ==> pi/8
heigtRec = 2.5;% meters

% Creat grid table
for ig = 1:1
    freq_res = Fs/fft_Rang;% range_grid
    freq_grid = (0:fft_Rang-1).'*freq_res;
    rng_grid = freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;
    
    w = [-180:4:180]; % angle_grid
    agl_grid = asin(w/180)*180/pi; % [-1,1]->[-pi/2,pi/2]
    
    % velocity_grid
    dop_grid = fftshiftfreqgrid(fft_Vel,1/Tc); % now fs is equal to 1/Tc
    vel_grid = dop_grid*lambda/2;   % unit: m/s, v = lamda/4*[-fs,fs], dopgrid = [-fs/2,fs/2]
    % vel_grid=3.6*vel_grid;        % unit: km/h
end

%% file information
folder_location = 'D:\tmp\ee596data\';

files = dir(folder_location); % find all the files under the folder
n_files = length(files);

WINDOW =  255;
NOVEPLAP = 242;
    
for inum = 16:22
    file_name = files(inum).name;
    file_loc = strcat(folder_location,file_name);  
    data = load(file_loc);
    data = data.data_saved;
    n_frame = size(data,1);
    data_conca = [];
    STFT_data = [];

    for j = 1:8
        data_conca_temp = [];
        for i = 1:n_frame
            data_conca_temp = [data_conca_temp, squeeze(data(i,j,:))'];
        end
        data_conca = [data_conca;data_conca_temp];
    end
    
%% STFT
    for h = 1:4
        [S,F,T] = spectrogram(data_conca(h,:),WINDOW,NOVEPLAP,256,1/Tc,'centered');
        v_grid_new = F*lambda/2;
        
        %% plot figure
        if h==1
            STFT_data = S;
            figure()
            axh = mesh(T-T(1),v_grid_new,abs(S));
            view(0,90)
            xlabel('time /s')
            ylabel('velocity m/s')
            title('SFFT heatmap')
            colorbar
        else
            STFT_data = cat(3,STFT_data,S);
        end
    end
    
    %% Normalize data
    max_val = 5.4e+08;
    STFT_data = STFT_data./max_val;
    STFT_data = single(STFT_data);
    
    %% store data
    interval = 50;
    stft_len = length(S);
    img_w = 256;
    index = 0;
    data_store_loc = strcat('D:\tmp\ee596prepro\',file_name(1:18),'\data');
    file_store_loc = strcat('D:\tmp\ee596prepro\',file_name(1:18),'\file');
    if ~exist(data_store_loc, 'dir') % check the folder exist
        mkdir(data_store_loc);
    end
    if ~exist(file_store_loc, 'dir') % check the folder exist
        mkdir(file_store_loc);
    end
    
    for L=1:interval:stft_len-img_w
        data_store = STFT_data(:,L:L+img_w-1,:);
        data_store_name = strcat(data_store_loc,'\',num2str(index,'%06d'),'.mat');
        index = index+1;
        eval(['save(data_store_name,''data_store'',''-v6'');'])
    end
    
%     % store last imgae
%     data_store = STFT_data(:,stft_len-interval+1:stft_len,:);
%     data_store_name = strcat(data_store_loc,'\',num2str(index,'%06d'),'.mat');
%     eval(['save(data_store_name,''data_store'',''-v6'');'])
    
    data_all_store_name = strcat(file_store_loc,'\',file_name(1:19),'alldata.mat');
    eval(['save(data_all_store_name,''STFT_data'',''-v6'');'])
    
    figure_store_name = strcat(file_store_loc,'\',file_name(1:19),'stftheatmap.png');
    eval(['saveas(axh,figure_store_name,''png'');'])
    close

end