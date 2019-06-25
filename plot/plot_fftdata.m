function [rng_grid vel_grid angle]=plot_fftdata( Xcube,DopData,AngleData,fc,Fs,sweepSlope)

c = physconst('LightSpeed');                % Speed of light in air (m/s)
lambda = c/fc;  
Nr=size(Xcube,1);   %%%length of Chirp
Ne=size(Xcube,2);   %%%number of receiver
Nd=size(Xcube,3);   %%%length of chirp loop
fft_Rang=size(DopData,1);
fft_Vel=size(DopData,3);

%% vel_grid
num_rng_samples=Nr;    %%%%500点的快时间信号长度（range），所以对应的dop的慢时间信号长度，采样率/500.
dop_grid=fftshiftfreqgrid(fft_Vel,Fs/num_rng_samples);
vel_grid=dop_grid*lambda/2;   %%%% m/s
% vel_grid=3.6*vel_grid;        %%%% km/h

%% rng_grid
frediff_grid=fftshiftfreqgrid(fft_Rang,Fs);
rng_grid=frediff_grid*c/sweepSlope/2;%%% d=frediff_grid*c/sweepSlope/2;
% rng_grid=rng_grid(end:-1:1);

%% ang_grid
w = [-180:2:180]; 
angle=asin(w/180)*180/pi;

for i=1:size(angle,2)
    yvalue(i,:)=(sin(angle(i)*pi/180 )).*rng_grid;
end
for i=1:size(angle,2)
    xvalue(i,:)=(cos(angle(i)*pi/180)).*rng_grid;
end

%% Plot 2D-FFT
Xbf = DopData(:,1,:);
Xbf = reshape(Xbf,fft_Rang,fft_Vel); 
Xpow = abs(Xbf).^2;
noisefloor = db2pow(50);
Xsnr=Xpow;
% Xsnr = pow2db(Xpow/noisefloor);

figure()
surf(vel_grid,rng_grid,Xsnr);
view(90,90)
title('2D-FFT---Lab Environment')
xlabel('Velocity(m/s)')
ylabel('Range(m)')
set(gca, 'YDir', 'normal')
% axis([-5 5 0 5]);
colormap(jet);
h=colorbar; 
% caxis([40 120])
set(h,'FontWeight'); 
title(h,'SNR(dB)');
grid off
shading interp

clear Xsnr;
clear Xbf;

%% plot 3D-FFT
% Xpow = abs(AngleData).^2;
% % Xpow=squeeze(Xpow(:,:,65));
% Xpow = max(Xpow,[],3);
% noisefloor = db2pow(-15);
% Xsnr=Xpow;
% % Xsnr = pow2db(Xpow/noisefloor);

% figure()
% surf(xvalue,yvalue,Xsnr')
% title('3D-FFT---Lab Environment')
% view(90,90)
% axis([ 0 inf -inf inf ])
% view(-90,90)
% set(gca,'YDir','reverse')
% xlabel('Y(m)')
% ylabel('X(m)')
% colormap(jet);
% h=colorbar; 
% % caxis([40 120])
% set(h,'FontWeight'); 
% title(h,'SNR(dB)');
% grid off
% shading interp


% figure()
% surf(angle,rng_grid,Xsnr);
% axis([-90 90 0 5]);
% view(0,90)
% grid off
% shading interp
% 
% title('3D-FFT---Lab Environment')
% % set(gca,'YDir','reverse')
% xlabel('Angle of arrive(deg)')
% ylabel('Range(m)')
% set(gca,'YDir','normal')
% colormap(jet);
% h=colorbar; 
% % caxis([40 120])
% set(h,'FontWeight'); 
% title(h,'SNR(dB)');
end








% imagesc(angle,rnggrid,Xsnr)
% axis([-90 90 -250 250])
% set(gca, 'YDir', 'normal')
% colormap(jet)
% xlabel('angle of arrive(deg)')
% ylabel('Range(m)')
% h=colorbar; 
% set(h,'FontWeight'); 
% title(h,'SNR(dB)');





function freq_grid = fftshiftfreqgrid(N,Fs)
%fftshiftfreqgrid Generate frequency grid
freq_res = Fs/N;
freq_grid = (0:N-1).'*freq_res;
Nyq = Fs/2;
half_res = freq_res/2;
if rem(N,2) % odd
    idx = 1:(N-1)/2;
    halfpts = (N+1)/2;
    freq_grid(halfpts) = Nyq-half_res;
    freq_grid(halfpts+1) = Nyq+half_res;
else
    idx = 1:N/2;
    hafpts = N/2+1;
    freq_grid(hafpts) = Nyq;
end
freq_grid(N) = Fs-freq_res;
freq_grid = fftshift(freq_grid);
freq_grid(idx) = freq_grid(idx)-Fs;
end
