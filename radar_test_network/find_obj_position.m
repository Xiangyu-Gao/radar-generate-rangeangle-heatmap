function cur_pos = find_obj_position(Angdata,init_pos,IS_Find_Init_Pos,Is_Det_Static)
Nr = size(Angdata,1);
Ne = size(Angdata,2);

if ~Is_Det_Static % remove static components
    static_comp = sum(Angdata,3)/size(Angdata,3);
    Angdata = Angdata - static_comp;
end

Sum_data = sum(abs(Angdata),3); % sum the magnitude of all chirps

if IS_Find_Init_Pos % IS_Find_Init_Pos=1 ==>find the initial object position in Range-Angle heatmap
    ran_avoid_width = 15;
    ran_min = ran_avoid_width;
    ran_max = Nr-ran_avoid_width;
    ang_min = 1;
    ang_max = Ne;
else %IS_Find_Init_Pos=0 ==>find the current object position in Range-Angle heatmap given the initial position
    % init_pos format [Range,Angle]
    ran_width = 2;% search width for range
    ang_width = 2;% search width for angle
    ran_min = max(init_pos(1)-ran_width,4);
    ran_max = min(init_pos(1)+ran_width,Nr);
    ang_min = max(init_pos(2)-ang_width,1);
    ang_max = min(init_pos(2)+ang_width,Ne);
end

% find the maximun value in given region and regard it is the object
[cur_pos] = find_2Dmax(Sum_data,ran_min,ran_max,ang_min,ang_max);
end