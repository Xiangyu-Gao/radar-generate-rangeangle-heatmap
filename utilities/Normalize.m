function [Angdata] = Normalize(Xcube)
max_val = 5e+03; % unwindowed max value
Xcube = Xcube./max_val;
Angdata = single(Xcube);
end