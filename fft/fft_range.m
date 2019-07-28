function [Rangedata]=fft_range(Xcube,fft_Rang)
%%%%  Xcube : Nr*Ne*Nd , original data
%%%   fft_Rang: range fft length
%%%   fft_Vel:  velocity fft length(2D-FFT)
%%%   fft_Ang:  angle fft length(3D FFT)

Nr=size(Xcube,1);   %%%length of Chirp (number of samples)
Ne=size(Xcube,2);   %%%number of receiver
Nd=size(Xcube,3);   %%%length of chirp loop

for i=1:Ne
    for j=1:Nd
%        win_rng =Xcube(:,i,j).*hanning(Nr);
       win_rng =Xcube(:,i,j);
       Rangedata(:,i,j)=fft(win_rng,fft_Rang);
    end
end
end

