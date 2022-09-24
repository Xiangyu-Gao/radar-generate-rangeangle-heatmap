Pt = 12.5; % dBm
GT = 1; % constant, we didnot find this value in ti datasheet, assume it has be embedded in Pt alreadly
GR = 34; % dB, it should be 34, not 24 in the paper, sorry for the inconvenience
lambda = 0.0038961; % m
sigma =  1;
k = 1.38e-23;
T = 290;
B = 4e6;
F = 15; % dB
SNR = 2; % dB

P_min = k * T * B * 10^(F/10) * 10^(SNR/10);
R_max = ((10^(Pt/10)*1e-3 * GT * 10^(GR/10) * lambda^2 * 1) / ((4*pi)^3 * P_min))^(1/4)