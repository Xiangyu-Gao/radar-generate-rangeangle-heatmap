clc
clear all
close all

capture_date_list = ["2019_04_09"];

for ida = 1:length(capture_date_list)
    capture_date = capture_date_list(ida);
    folder_location_data = strcat('F:/Croped_Data/', capture_date, '/');
    folder_location_saveddata = strcat('F:/Assemble_CropedData/', capture_date, '/');
    folder_location_saveddata_single = strcat('F:/Singlelem_CropedData/', capture_date, '/');  
    files = dir(folder_location_data); % find all the files under the folder
    n_files = length(files);
    
    for inum = 3:n_files
        file_name = files(inum).name;
        % generate file name and folder
        file_location_data = strcat(folder_location_data, file_name,'/');
        file_location_saveddata = strcat(folder_location_saveddata, ...
            file_name,'/');
        file_location_saveddata_single = strcat(folder_location_saveddata_single, ...
            file_name,'/');
        if ~exist(file_location_saveddata, 'dir') % check the folder exist
            mkdir(file_location_saveddata);
        end
        if ~exist(file_location_saveddata_single, 'dir') % check the folder exist
            mkdir(file_location_saveddata_single);
        end
        
        chunks = dir(file_location_data);
        saved_data_label = [];
        saved_data_stopframe = [];
        saved_data_id = [];
        num_id = 0;
             
        for ifa = 3:length(chunks)
            chunk_name = chunks(ifa).name;
            chunk_name_elem = string(split(chunk_name, '_'));
            chunk_location_data = strcat(file_location_data, chunk_name,'/');
            %% read data file
            Chunkdata = load(chunk_location_data);
            Chunkdata = Chunkdata.saved_data;
            obj_class = chunk_name_elem(6);
            obj_trackid = chunk_name_elem(7);
            obj_trackid = str2num(obj_trackid{1}(1:2));
            
            %% sort and assemble the files for different tracking id
            if ifa == 3
                frame_start = str2num(chunk_name_elem(5));
                frame_current = frame_start;
            else
                frame_current = str2num(chunk_name_elem(5));
            end
            
            if frame_current == frame_start % initialize the saved_data array
                num_id = num_id + 1;
                saved_data_id = [saved_data_id, obj_trackid];
                saved_data_label = [saved_data_label, obj_class]; % temporary decision
                saved_data_stopframe = [saved_data_stopframe, frame_current];
                eval(['saved_data', num2str(num_id), ' = Chunkdata;']);
                eval(['saved_data_labels', num2str(num_id), ' = obj_class;']);
                
            else % append the saved_data array
                % search the if it is new
                [~,I] =  find(saved_data_id == obj_trackid);
                if ~isempty(I)
                    if abs(saved_data_stopframe(I) - frame_current) < 10
                    eval(['saved_data', num2str(I), '= cat(3, saved_data',...
                        num2str(I),', Chunkdata);']);
                    eval(['saved_data_labels', num2str(I), ...
                        '= cat(2, saved_data_labels', num2str(I),', obj_class);']);
                    saved_data_stopframe(I) = frame_current;
                    
                    else %ignore
                    end
                
                else % create a new track id
                    num_id = num_id + 1;
                    saved_data_id = [saved_data_id, obj_trackid];
                    saved_data_label = [saved_data_label, obj_class]; % temporary decision
                    saved_data_stopframe = [saved_data_stopframe, frame_current];
                    eval(['saved_data', num2str(num_id), ' = Chunkdata;']);
                    eval(['saved_data_labels', num2str(num_id), ' = obj_class;']);
                end
             
            end
            
        end
        %% re-decide the class of each track
        for icd = 1:length(saved_data_stopframe)
            eval(['mof = find_max_occur(saved_data_labels', ...
                num2str(icd),');']);
            if mof == 'pedestrian'
                saved_data_label(icd) = 'pedestrian';
            elseif mof == 'car'
                saved_data_label(icd) = 'car';
            elseif mof == 'cyclist'
                saved_data_label(icd) = 'cyclist';
            else
            end
        end

        %% save data
        for icd = 1:length(saved_data_stopframe)
            saved_assemb_chunk_location = strcat(file_location_saveddata, ...
                file_name, '_', saved_data_label(icd), '_', ...
                num2str(saved_data_id(icd), '%02d'), '.mat');
            saved_single_elem_location = strcat(file_location_saveddata_single, ...
                file_name, '_', saved_data_label(icd), '_', ...
                num2str(saved_data_id(icd), '%02d'), '.mat');
            eval(['To_save_data = saved_data', num2str(icd), ';']);
            saved_data_single = To_save_data(8,10,:);
            save(saved_assemb_chunk_location,'To_save_data','-v6'); 
            save(saved_single_elem_location,'saved_data_single','-v6');
        end
        disp(file_name)
    end
end
