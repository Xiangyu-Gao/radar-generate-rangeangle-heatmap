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
fft_Vel = 256;
fft_Ang = 91;
widthRec = 25; % degrees (19 bins)
heigtRec = 3; % meters (15 bins)
widthBins = 18; % actual = 19 with the central one
heigtBins = 14; % actual = 15 with the central one
IS_SAVE_Data = true;% 1 ==> save range-angle data and heatmap figure

% Creat grid table
freq_res = Fs/fft_Rang;% range_grid
freq_grid = (0:fft_Rang-1).'*freq_res;
rng_grid = freq_grid*c/sweepSlope/2;% d=frediff_grid*c/sweepSlope/2;
rng_grid = rng_grid(4:fft_Rang-3); % crop rag_grid

w = [-180:4:180]; % angle_grid
agl_grid = asin(w/180)*180/pi; % [-1,1]->[-pi/2,pi/2]

% velocity_grid
dop_grid = fftshiftfreqgrid(fft_Vel,1/Tc); % now fs is equal to 1/Tc
vel_grid = dop_grid*lambda/2;   % unit: m/s, v = lamda/4*[-fs,fs],
                                % dopgrid = [-fs/2,fs/2]

capture_date_list = ["2019_04_09", "2019_04_30", "2019_05_09", ...
    "2019_05_23", "2019_05_28", "2019_05_29"];

for ida = 1:length(capture_date_list)
    capture_date = capture_date_list(ida);
    folder_location_data = strcat('F:/Processed_data/UNWINDOWED/', ...
        capture_date, '/');
    folder_location_detect = strcat('F:/dets_3d/', capture_date, '/');
    folder_location_saveddata = strcat('F:/Croped_Data/', ...
        capture_date,'/');
    folder_location_savedimage = strcat('F:/Croped_Data_Image/', ...
        capture_date,'/');
    files = dir(folder_location_data); % find all the files under the folder
    n_files = length(files);
    
    for inum = 3:n_files
        file_name = files(inum).name;
        % check if the file is static scenario, detect static objects.
        Is_Det_Static = 1;
        if contains(file_name,'ss1') | contains(file_name,'s1s')
            Is_Det_Static = 1;
        else
            Is_Det_Static = 0;
        end
        
        % generate file name and folder
        file_location_data = strcat(folder_location_data, file_name,'/');
        file_location_detect = strcat(folder_location_detect, file_name, ...
            '/dets_3d_track_filtered/');
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
        
        for ifa = 3:length(frames)
            frame_name = frames(ifa).name;
            frame_index = str2num(frame_name(20:25));
            frame_location_data = strcat(file_location_data, frame_name);
            frame_location_detect = strcat(file_location_detect, ...
                num2str(frame_index,'%010d'),'.txt');
            if frame_index == 0 % ignore the first frame
                
            else
                %% Read Radar data
                Angdata = load(frame_location_data);
                Angdata = Angdata.Angdata_crop;
                %% Read Camera Results
                Cam_rest = readtable(frame_location_detect, ...
                    'ReadVariableNames',false);
                Cam_rest = table2array(Cam_rest);
                if isempty(Cam_rest)
                    
                else
                IF_HAS_PLOT = 0;
                for icr = 1:size(Cam_rest,1)
                    % get object class
                    if Cam_rest(icr,1) == 0
                        obj_class = 'pedestrian';
                    elseif Cam_rest(icr,1) == 1
                        obj_class = 'car';
                    elseif Cam_rest(icr,1) == 2
                        obj_class = 'cyclist';
                    else
                        obj_class = 'none';
                    end
                    colorid = Cam_rest(icr,1);
                    
                    % get object range and angle
                    obj_x = Cam_rest(icr,12);
                    obj_y = Cam_rest(icr,13);
                    obj_z = Cam_rest(icr,14);
                    obj_Range = sqrt(obj_x^2 + obj_y^2 + obj_z^2);
                    obj_Angle = atand(obj_x/obj_z);
                    
                    % get object tracking id
                    obj_id = Cam_rest(icr,17);
                    
                    if obj_Range > 26.1 % ingore the objets whose range is 
                                        %greater than 26m
                    else
                %% Detect objects in radar images
                    [~,rng_ele] = min(abs(rng_grid-obj_Range));
                    [~,agl_ele] = min(abs(agl_grid-obj_Angle));
                    init_pos = [rng_ele,agl_ele];
                    cur_pos = find_obj_position(Angdata,init_pos, ...
                        0,Is_Det_Static);
                
                %% Give id to detected objects 
                % plot the boudning box of cutting area
                    if icr == 1
                        [axh] = plot_rangeAng(Angdata, ...
                            rng_grid, agl_grid);
                        IF_HAS_PLOT = 1;
                        % plot cut out area
                        posiObjCam = [agl_grid(cur_pos(2))-widthRec/2, ...
                            rng_grid(cur_pos(1))-heigtRec/2];
                        hold on
                        plot_rectangle(posiObjCam, widthRec, heigtRec, colorid);
                        % text id on heatmap
                        txt = strcat('id: ', num2str(obj_id));
                        text(agl_grid(cur_pos(2))-10, ...
                            rng_grid(cur_pos(1))+1,1,txt,'Color','r');
                    
                    elseif IF_HAS_PLOT == 0
                        % replot the heatmap since the first one is ignored
                        [axh] = plot_rangeAng(Angdata, ...
                            rng_grid, agl_grid);
                        IF_HAS_PLOT = 1;
                        % plot cut out area
                        posiObjCam = [agl_grid(cur_pos(2))-widthRec/2, ...
                            rng_grid(cur_pos(1))-heigtRec/2];
                        hold on
                        plot_rectangle(posiObjCam, widthRec, heigtRec, colorid);
                        % text id on heatmap
                        txt = strcat('id: ', num2str(obj_id));
                        text(agl_grid(cur_pos(2))-10, ...
                            rng_grid(cur_pos(1))+1,1,txt,'Color','r');
                    
                    else
                        % plot cut out area
                        posiObjCam = [agl_grid(cur_pos(2))-widthRec/2, ...
                            rng_grid(cur_pos(1))-heigtRec/2];
                        hold on
                        plot_rectangle(posiObjCam, widthRec, heigtRec, colorid);
                        % text id on heatmap
                        txt = strcat('id: ', num2str(obj_id));
                        text(agl_grid(cur_pos(2))-10, ...
                            rng_grid(cur_pos(1))+1,1,txt,'Color','r');
                    end
                %% cut out data and save
                    if IS_SAVE_Data
                    saved_chunk_name = strcat(file_name, '_', ...
                        num2str(frame_index,'%06d'), '_', obj_class, ...
                        '_', num2str(obj_id,'%02d'), '.mat');
                    saved_chunk_location = strcat(file_location_saveddata, ...
                        saved_chunk_name);
                    
                    if cur_pos(1)-heigtBins/2 < 1 || cur_pos(1)+heigtBins/2 ...
                            > 122 || cur_pos(2)-widthBins/2 < 1 || cur_pos(2) ...
                            +widthBins/2 > 91
                        
                    else
                        saved_data = Angdata(cur_pos(1)-heigtBins/2: ...
                            cur_pos(1)+heigtBins/2, cur_pos(2)-widthBins/2: ...
                            cur_pos(2)+widthBins/2,:);
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
                
                end  
            end
            frame_index
        end
    end
end