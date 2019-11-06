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
Fs = 11*10^6;
sweepSlope = 33.023e12;
samples = 256;
loop = 255;
Tc = 66e-6; %us
fft_Rang = 256;
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

% Algorithm parameters
frame_start = 1;
frame_end = 205;
option = 0; % option=0,only plot ang-range; option=1, only generate the synthetic(merged) range-angle heatmap;
% option=2,only record raw data in format of matrix; option=3,ran+dop+angle estimate;
IS_Plot_RD = 0; % 1 ==> plot the Range-Doppler heatmap
IS_SAVE_Data = 1;% 1 ==> save range-angle data and heatmap figure
Is_Det_Static = 1;% 1==> detection includes static objects (!!! MUST BE 1 WHEN OPYION = 1)
Is_Windowed = 0;% 1==> Windowing before doing angle fft
num_stored_figs = 900;% the number of figures that are going to be stored
cali_n = 3; % the number of range bins that need to be calibrated
neidop_n = 3; % the number of neighbored bins around the selected the doppler

%% file information
capture_date = '2019_07_25';
folder_location = strcat('/mnt/disk1/CR_DATASET/',capture_date);
files = dir(folder_location); % find all the files under the folder
n_files = length(files);
% 2019_04_30 inum range [3:7,9:14,16:21]
% 2019_05_28 inum range [3:22]
processd_files = [14:14];

for index = 1:length(processd_files)
    inum = processd_files(index)
    file_name = files(inum).name;
    % generate file name and folder
    file_location = strcat(folder_location,'/',file_name,'/rad_reo_zerf/adc_data_0.bin');
    file_location2 = strcat(folder_location,'/',file_name,'/rad_reo_zerf/adc_data_1.bin');
    for ign = 1:1
        if option == 0 && Is_Windowed == 0
            saved_folder_name = strcat(folder_location,'/',file_name,'/UNWIN_PROC_MAT_DATA');
            saved_fig_folder_name = strcat(folder_location,'/',file_name,'/UNWIN_HEATMAP');
            %     saved_pos_folder_name = strcat(folder_location,'/',file_name,'/UNWIN_PROC_MAT_DATA');
            %     saved_pos_file_name = strcat(folder_location,'/',file_name,'/UNWIN_PROC_MAT_DATA');
        elseif option == 0 && Is_Windowed == 1
            saved_folder_name = strcat(folder_location,'/',file_name,'/UNWIN_PROC_MAT_DATA');
            saved_fig_folder_name = strcat(folder_location,'/',file_name,'/UNWIN_HEATMAP');
            
        elseif option == 1 && Is_Windowed == 0
            
        elseif option == 1 && Is_Windowed == 1
            
        end
        
        if ~exist(saved_folder_name, 'dir') % check the folder exist
            mkdir(saved_folder_name);
        end
        if ~exist(saved_fig_folder_name, 'dir') % check the folder exist
            mkdir(saved_fig_folder_name);
        end
        %         if ~exist(saved_pos_folder_name, 'dir') % check the folder exist
        %         mkdir(saved_pos_folder_name);
        %         end
    end
    
    %% read the data file
        data=readDCA16xx(file_location);
        data_all1=reshape(data,size(data,1)*size(data,2),[]); % reshape 4 channels into 1
        data2=readDCA16xx(file_location2);
        data_all2=reshape(data2,size(data2,1)*size(data2,2),[]); % reshape 4 channels into 1
        data_all = [data_all1;data_all2];
        data_length=length(data_all);
        data_each_frame=samples*loop*2*Rx;
        Frame_num=data_length/data_each_frame;
%     data2 = readDCA1000(file_location);
%     figure()
%     plot([1:128],20*log2(real(data2(1,1:128))))
%     hold on
%     plot([1:128],20*log2(imag(data2(1,1:128))))
%     %         axis([0,128,-100,40])
%     grid on
%     figure()
%     plot([1:128],20*log2(real(data2(2,1:128))))
%     hold on
%     plot([1:128],20*log2(imag(data2(2,1:128))))
%     figure()
%     plot([1:128],20*log2(real(data2(3,1:128))))
%     hold on
%     plot([1:128],20*log2(imag(data2(3,1:128))))
%     figure()
%     plot([1:128],20*log2(real(data2(4,1:128))))
%     hold on
%     plot([1:128],20*log2(imag(data2(4,1:128))))
    %     % FOR CHIRP 1
    %     % Range FFT
    %     figure()
    %     plot([1:128],20*log2(abs(real(data2(1,1:128)))))
    %     hold on
    %     plot([1:128],20*log2(abs(imag(data2(1,1:128)))))
    %     %         axis([0,128,-100,40])
    %     grid on
    %     % check whether Frame number is an integer
    %
    if Frame_num == 900
        frame_end = Frame_num;
    elseif abs(Frame_num-900) < 30
        fprintf('Error! Frame number is not an integer');
        frame_start = 900 - fix(Frame_num) + 1;
        % zero fill the data_all
        num_zero_fill = 900*data_each_frame - data_length;
        data_all = [zeros(num_zero_fill,1); data_all];
        frame_end = 900;
    elseif abs(Frame_num-900) >= 30 && Frame_num == fix(Frame_num)
        frame_end = Frame_num;
    else
        
    end
    
    caliDcRange_chirp1 = [];
    caliDcRange_chirp2 = [];
    obj_pos = [];
    obj_pos_value = [];
    init_pos = [];
    
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
        Xcube_chirp1=permute(Frame_loop_chirp1_Rx(:,:,:,i),[1 2 3]);
        Xcube_chirp2=permute(Frame_loop_chirp2_Rx(:,:,:,i),[1 2 3]);
        
        %         % calculate energy (evalution)
        %         cal_Enegry(Xcube_chirp1,Xcube_chirp2,Framedata)
        %         plot_singnal_time(Xcube_chirp1)
        
        if option == 0
            %% plot ang-range and find the location of objects
            for ip = 1:1
                if i > frame_start - 1
                    % FOR CHIRP 1
                    % Range FFT
%                     figure()
%                     plot([1:128],20*log2(abs(real(Xcube_chirp1(:,1,1)))))
%                     hold on
%                     plot([1:128],20*log2(abs(imag(Xcube_chirp1(:,1,1)))))
%                     %         axis([0,128,-100,40])
%                     grid on
%                     
%                     figure()
%                     plot([1:128],20*log2(abs(real(Xcube_chirp1(:,4,1)))))
%                     hold on
%                     plot([1:128],20*log2(abs(imag(Xcube_chirp1(:,4,1)))))
%                     %         axis([0,128,-100,40])
%                     grid on
%                     
%                     figure()
%                     plot([1:128],20*log2(abs(real(Xcube_chirp1(:,3,1)))))
%                     hold on
%                     plot([1:128],20*log2(abs(imag(Xcube_chirp1(:,3,1)))))
%                     %         axis([0,128,-100,40])
%                     grid on
%                     
%                     figure()
%                     plot([1:128],20*log2(real(Xcube_chirp1(:,2,1))))
%                     hold on
%                     plot([1:128],20*log2(imag(Xcube_chirp1(:,2,1))))
%                     %         axis([0,128,-100,40])
%                     grid on
%                     
                    [Rangedata_chirp1] = fft_range(Xcube_chirp1,fft_Rang);
%                     figure()
%                     plot(rng_grid,20*log10(abs(Rangedata_chirp1(:,1,2)))-190)
%                     axis([0,28,-130,0])
%                     grid on
%                     caliDcRangeSig
                     [Rangedata_chirp1,caliDcRange_chirp1] = caliDcRangeSig(Rangedata_chirp1,i,loop,frame_start,caliDcRange_chirp1,cali_n);
                    % Check whether to plot range-doppler heatmap
                    if IS_Plot_RD == 1
                        % Doppler FFT
                        [Dopdata_chirp1] = fft_doppler(Rangedata_chirp1,fft_Vel);
                        
                        % plot range-doppler
                        plot_rangeDop(Dopdata_chirp1,vel_grid,rng_grid)
                    else
                        
                    end
                    
                    % FOR CHIRP 2
                    % Range FFT
                    [Rangedata_chirp2] = fft_range(Xcube_chirp2,fft_Rang);
                    
                    % caliDcRangeSig
                    [Rangedata_chirp2,caliDcRange_chirp2] = caliDcRangeSig(Rangedata_chirp2,i,loop,frame_start,caliDcRange_chirp2,cali_n);
                    
                    % Angle FFT
                    % need to do doppler compensation on Rangedata_chirp2 in future
                    Rangedata_merge = [Rangedata_chirp1,Rangedata_chirp2];
                    Angdata = fft_angle(Rangedata_merge,fft_Ang,Is_Windowed);
                    
                    % Normalize range-angle data
                   
                    Angdata = Angdata(1:128,:,:);
                    [Angdata] = Normalize(Angdata);
                    if i < frame_start + num_stored_figs % plot Range_Angle heatmap
                        [axh] = plot_rangeAng(Angdata,rng_grid(1:128),agl_grid);
                    end
                    
                    
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
                    
                    if IS_SAVE_Data
                        % save range-angle heatmap to .mat file
                        saved_file_name = strcat(saved_folder_name,'/',file_name,'_',num2str(i-1,'%06d'),'.mat');
                        eval(['save(saved_file_name,''Angdata'',''-v6'');'])
                        
                        if i < frame_start + num_stored_figs % plot rectangle
                            %                     posiObjCam = [agl_grid(cur_pos(2))-widthRec/2,rng_grid(cur_pos(1))-heigtRec/2];
                            %                     hold on
                            %                     plot_rectangle(posiObjCam,widthRec,heigtRec);
                            % save to figure
                            saved_fig_file_name = strcat(saved_fig_folder_name,'/','frame_',num2str(i-1,'%06d'),'.png');
                            eval(['saveas(axh,saved_fig_file_name,''png'');'])
                            close
                        end
                    end
                    i % print index i
                end
            end
        elseif option == 1
            %% generate the synthetic(merged) range-angle heatmap
            for iS = 1:1
                if i > frame_start-1
                    x_dop = [];
                    x_dop_C = [];
                    
                    % FOR CHIRP 1
                    % Range FFT
                    [Rangedata_chirp1] = fft_range(Xcube_chirp1,fft_Rang);
                    % caliDcRangeSig,cali_n=3
                    [Rangedata_chirp1,caliDcRange_chirp1] = caliDcRangeSig(Rangedata_chirp1,i,loop,frame_start,caliDcRange_chirp1,cali_n);
                    
                    % FOR CHIRP 2
                    % Range FFT
                    [Rangedata_chirp2] = fft_range(Xcube_chirp2,fft_Rang);
                    % caliDcRangeSig
                    [Rangedata_chirp2,caliDcRange_chirp2] = caliDcRangeSig(Rangedata_chirp2,i,loop,frame_start,caliDcRange_chirp2,cali_n);
                    
                    % Generate range-doppler heatmap for chirp1
                    [Dopdata_chirp1] = fft_doppler(Rangedata_chirp1,fft_Vel);% Doppler FFT
                    [Dopdata_chirp2] = fft_doppler(Rangedata_chirp2,fft_Vel);% Doppler FFT
                    
                    if IS_Plot_RD == 1
                        % plot range-doppler(with DC removal)
                        plot_rangeDop(Dopdata_chirp1,vel_grid,rng_grid)
                    else
                    end
                    
                    Dop_sum = squeeze(sum(Dopdata_chirp1,2)/size(Dopdata_chirp1,2)); % Sum 4 receive antennas
                    
                    % CFAR to detect all velocity component
                    for rani = cali_n+1:fft_Rang  % from range 4(because the DC component in range1-3 have been canceled)
                        x_detected = cfar_ca1D(Dop_sum(rani,:),4,4,3.5,1);
                        x_dop = [x_dop,x_detected];
                    end
                    
                    % deal with the empty x_dop (CFAR didn't detect the object)
                    if length(x_dop) == 0
                        % find the maximum velocity component in heatmap
                        [peak_pos] = find_2Dmax(Dop_sum,cali_n+1,fft_Rang,1,fft_Vel);
                        x_dop = [x_dop,[peak_pos(2),0,0]'];
                    end
                    
                    [x_dop_U,~,~] = unique(x_dop(1,:)); % make detecton result unique
                    
                    for dopi = 1:length(x_dop_U) % add the neighbor bins
                        x_dop_C = [x_dop_C,[max(x_dop_U(dopi)-neidop_n,1):1:min(x_dop_U(dopi)+neidop_n,fft_Vel)]];
                    end
                    
                    [x_dop_CU,~,~] = unique(x_dop_C(1,:)); % make detecton result unique again
                    
                    % Angele FFT
                    Dopdata_merge = [Dopdata_chirp1,Dopdata_chirp2];
                    Angdata = fft_angle(Dopdata_merge,fft_Ang,Is_Windowed);
                    
                    % sum selected range-angle heatmaps, the indexes are in x_dop_CU
                    Angdata_merge = sum(Angdata(:,:,x_dop_CU),3)/length(x_dop_CU);
                    Angdata_merge_RemoveDC = (sum(Angdata(:,:,x_dop_CU),3) - Angdata(:,:,65))/(length(x_dop_CU) - 1);
                    
                    % plot Range_Angle heatmap
                    if i < frame_start + num_stored_figs
                        [axh] = plot_rangeAng(Angdata_merge_RemoveDC,rng_grid,agl_grid);
                    end
                    
                    if i == frame_start % search the initial position of object
                        cur_pos = find_obj_position(Angdata_merge_RemoveDC,init_pos,1,1);
                        init_pos = cur_pos;
                        obj_pos = [obj_pos;i,cur_pos]; % obj_pos list format [frame, range, angle]
                        obj_pos_value = [obj_pos_value;i,rng_grid(cur_pos(1)),agl_grid(cur_pos(2))];
                    else % search the position of object in specific range(temporarily)
                        cur_pos = find_obj_position(Angdata_merge_RemoveDC,init_pos,0,1);
                        init_pos = cur_pos;
                        obj_pos = [obj_pos;i,cur_pos]; % obj_pos list format [frame, range, angle]
                        obj_pos_value = [obj_pos_value;i,rng_grid(cur_pos(1)),agl_grid(cur_pos(2))];
                    end
                    
                    if IS_SAVE_Data
                        [Angdata_merge] = Normalize(Angdata_merge);
                        % save range-angle heatmap to .mat file
                        saved_file_name = strcat(saved_folder_name,'/',data_name,'_',num2str(i-frame_start,'%06d'),'.mat');
                        eval(['save(saved_file_name,''Angdata_merge'',''-v6'');'])
                        
                        if i < frame_start + num_stored_figs % plot rectangle
                            posiObjCam = [agl_grid(cur_pos(2))-widthRec/2,rng_grid(cur_pos(1))-heigtRec/2];
                            hold on
                            plot_rectangle(posiObjCam,widthRec,heigtRec);
                            % save to figure
                            saved_fig_file_name = strcat(saved_fig_folder_name,'/','frame_',num2str(i,'%06d'),'.png');
                            eval(['saveas(axh,saved_fig_file_name,''png'');'])
                            close
                        end
                    end
                    i % print index i
                end
            end
        elseif option == 2
            %% record raw data in the form of matrix
            for ir = 1:1
                if i > frame_start-1
                    saved_file_name = strcat(data_name,'_',num2str(i,'%03d'),'.mat');
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
    
    %     if IS_SAVE_Data
    %     dlmwrite(saved_pos_file_name,obj_pos_value);
    %     end
end
