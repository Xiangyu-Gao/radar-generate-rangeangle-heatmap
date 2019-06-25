function [] = cal_Enegry(Xcube_chirp1,Xcube_chirp2,Framedata)

Xcube = [Xcube_chirp1,Xcube_chirp2];
Engy_chirp = squeeze(sum(abs(Xcube),1));
%%% for antenna 1
figure()
plot([1:size(Xcube,3)],20*log10(Engy_chirp(1,:)))
xlabel('chirp')
ylabel('dB')
title('Energy of chirp for Rx1')
%%% for antenna 2
figure()
plot([1:size(Xcube,3)],20*log10(Engy_chirp(8,:)))
xlabel('chirp')
ylabel('dB')
title('Energy of chirp for Rx4')

% %% total frame Energy
% figure()
% plot(20*log10(sum(abs(Framedata),1)))
% xlabel('Frame')
% ylabel('dB')
% title('Amplitude of Received signal')
end