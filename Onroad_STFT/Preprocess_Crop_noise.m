clc
clear all
close all

%% Parameters
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
Tc = 120e-6; % us
fft_Rang = 128;
new_fft_Rang = 134;
fft_Vel = 256;
fft_Ang = 128;
widthRec = 25; % degrees (19 bins)
heigtRec = 2; % meters (15 bins)
widthBins = 14; % actual = 15 with the central one
heigtBins = 10; % actual = 15 with the central one
IS_SAVE_Data = true;% 1 ==> save range-angle data and heatmap figure
crop_frame = 16;
colorid = 1; %'w'

% Creat grid table
freq_res = Fs/fft_Rang;% range_grid
freq_grid = (0:fft_Rang-1).'*freq_res;
rng_grid = freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;
rng_grid = rng_grid(4:fft_Rang-3); % crop rag_grid

new_freq_res = Fs/new_fft_Rang;% range_grid
new_freq_grid = (0:new_fft_Rang-1).'*new_freq_res;
new_rng_grid = new_freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;
new_rng_grid = new_rng_grid(4:new_fft_Rang-3); % crop rag_grid


w = linspace(-1,1,fft_Ang); % angle_grid
agl_grid = asin(w)*180/pi; % [-1,1]->[-pi/2,pi/2]

% velocity_grid
dop_grid = fftshiftfreqgrid(fft_Vel,1/Tc); % now fs is equal to 1/Tc
vel_grid = dop_grid*lambda/2;   % unit: m/s, v = lamda/4*[-fs,fs],
                                % dopgrid = [-fs/2,fs/2]

capture_date_list = ["2019_04_09", "2019_04_30", "2019_05_09", "2019_05_29"];
% capture_date_list = ["2019_05_09"];



for ida = 1:length(capture_date_list)
    capture_date = capture_date_list(ida);
    folder_location_data = strcat('/mnt/nas_crdataset/',capture_date, '/');
    folder_location_detect = strcat('/home/admin-cmmb/Documents/PROCSDATA/Noise/', capture_date, '/');
    folder_location_saveddata = strcat('/media/admin-cmmb/b746418b-1701-4336-b797-c64a6af72d56/Noise/Croped_Data/', ...
        capture_date,'/');
    folder_location_savedimage = strcat('/media/admin-cmmb/b746418b-1701-4336-b797-c64a6af72d56/Noise/Croped_Data_Image/', ...
        capture_date,'/');
    files = dir(folder_location_data); % find all the files under the folder
    n_files = length(files);
    
    for inum = 3:n_files
        file_name = files(inum).name;
        
        % generate file name and folder
        file_location_data = strcat(folder_location_data, file_name,'/WIN_PROC_MAT_DATA/');
        file_location_detect = strcat(folder_location_detect, file_name, '.txt');
        file_location_saveddata = strcat(folder_location_saveddata, ...
            file_name,'/');
        file_location_savedimage = strcat(folder_location_savedimage, ...
            file_name,'/');
        if ~exist(file_location_saveddata, 'dir') % check the folder exist
            mkdir(file_location_saveddata);
        end
        if ~exist(file_location_savedimage, 'dir') % check the folder exist
            mkdir(file_location_savedimage);
        end
            
        frames = dir(file_location_data);
        
        %% Read Camera Results
        Radar_table = readtable(file_location_detect);
        if ~isempty(Radar_table)
        Radar_label= table2array(Radar_table);
        frame_index_arr = Radar_label(:,1);
        dop_label = Radar_label(:,2);
        rng_label = Radar_label(:,3);
        agl_label = Radar_label(:,4);
        
        
        for ifa = 3:length(frames)-crop_frame+1
            frame_name = frames(ifa).name;
            frame_index = str2num(frame_name(20:25));
            frame_index_inlabel = find(frame_index_arr == frame_index);
            IF_HAS_PLOT = 0;
            
            %% Read Radar data
            if ifa == 3
                for isd = 0:crop_frame-1
                    load_frame_index = frame_index + isd;
                    load_frame_name = strrep(frame_name, ...
                        frame_name(20:25), num2str(load_frame_index, '%06d'));
                    frame_location_data = strcat(file_location_data, load_frame_name);
                    temp_angdata = load(frame_location_data);
                    eval(['Angdata_', num2str(isd),'=temp_angdata.Angdata_crop;'])
                end
                start_index = 0;
                
            else
                replace_index = mod(ifa-4,16);
                start_index = mod(ifa-4+1,16);
                load_frame_index = frame_index + crop_frame-1;
                load_frame_name = strrep(frame_name, ...
                    frame_name(20:25), num2str(load_frame_index, '%06d'));
                frame_location_data = strcat(file_location_data, load_frame_name);
                temp_angdata = load(frame_location_data);
                eval(['Angdata_', num2str(replace_index),'=temp_angdata.Angdata_crop;'])
            end
           
            %% read_label
            if ~isempty(frame_index_inlabel)
            for ila = 1:length(frame_index_inlabel)
                % read range+angle
                la = frame_index_inlabel(ila);
                assert(frame_index_arr(la,1) == frame_index)
                pran_idx = rng_label(la,1)+1;
                pang_idx = agl_label(la,1)+1;
            
            
            %% plot the boudning box of cutting area
                if ila == 1 
                    eval(['[axh] = plot_rangeAng(Angdata_', num2str(start_index), ...
                        ',new_rng_grid, agl_grid);'])

                    IF_HAS_PLOT = 1;
                    % plot cut out area
                    posiObjCam = [agl_grid(pang_idx)-widthRec/2, ...
                        new_rng_grid(pran_idx)-heigtRec/2];
                    hold on
                    plot_rectangle(posiObjCam, widthRec, heigtRec, colorid);


                else
                    posiObjCam = [agl_grid(pang_idx)-widthRec/2, ...
                        new_rng_grid(pran_idx)-heigtRec/2];
                    hold on
                    plot_rectangle(posiObjCam, widthRec, heigtRec, colorid);

                end
                    
            %% cut out data and save
                if IS_SAVE_Data
                saved_data = [];
                saved_chunk_name = strcat(file_name, '_', ...
                    num2str(frame_index,'%06d'), '_noise_', ...
                    num2str(la, '%2d'), '.mat');
                saved_chunk_location = strcat(file_location_saveddata, ...
                    saved_chunk_name);
                save_sequence = mod([start_index:start_index+crop_frame-1],crop_frame);
                
                if pran_idx-heigtBins/2 < 1 || pran_idx+heigtBins/2 ...
                        > 128 || pang_idx-widthBins/2 < 1 || pang_idx ...
                        +widthBins/2 > 128
                        
                else
                    for iss = 1:length(save_sequence)
                        eval(['temp_saved_data = Angdata_', num2str(save_sequence(iss)),';'])
                        saved_data_frame = temp_saved_data(pran_idx-heigtBins/2: ...
                            pran_idx+heigtBins/2, pang_idx-widthBins/2: ...
                            pang_idx+widthBins/2,:);
                        saved_data = cat(3, saved_data, saved_data_frame);
                    end
                    save(saved_chunk_location,'saved_data','-v6'); 
                end
              
                else
                end
                
            end
            end



            %% save the heatmap image with all boudning boxes
            if IS_SAVE_Data & IF_HAS_PLOT
                saved_image_name = strcat(file_location_savedimage, ...
                    file_name, '_',num2str(frame_index,'%06d'),'.png');
                saveas(axh,saved_image_name,'png');
                close
            else
            end
            
            frame_index
 
        end
        end
        
    end
end
