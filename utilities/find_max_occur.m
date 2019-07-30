function [q] = find_max_occur(saved_data_labels)

[uniqueXX, ~, J]=unique(saved_data_labels) ;
occ = histc(J, 1:numel(uniqueXX));
q = uniqueXX(occ == max(occ));
end