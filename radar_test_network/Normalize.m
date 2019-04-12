function [Angdata] = Normalize(Xcube)
max_val = 2e+07;
Xcube = Xcube./max_val;
Angdata = single(Xcube);
end