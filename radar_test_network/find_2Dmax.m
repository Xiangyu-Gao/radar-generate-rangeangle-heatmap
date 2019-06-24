function [cur_pos] = find_2Dmax(Sum_data,ran_min,ran_max,ang_min,ang_max)
% find the maximun value in given region and regard it is the object
aaa = Sum_data(ran_min:ran_max,ang_min:ang_max);
[val,idx] = max(aaa(:));
[ir,ic] = ind2sub(size(aaa),idx);
cur_pos(1) = ran_min + ir - 1;
cur_pos(2) = ang_min + ic - 1;
end