 function [Rangedata,DopData,AngData]=fft_Radar(Xcube,fft_Rang,fft_Vel,fft_Ang)
%%%%  Xcube : Nr*Ne*Nd , original data
%%%   fft_Rang: range fft length
%%%   fft_Vel:  velocity fft length(2D-FFT)
%%%   fft_Ang:  angle fft length(3D FFT)
%% 1DFFT
Nr=size(Xcube,1);   %%%length of Chirp
Ne=size(Xcube,2);   %%%length of receiver
Nd=size(Xcube,3);   %%%length of chirp loop

for i=1:Ne
    for j=1:Nd
       win_rng =Xcube(:,i,j).*blackman(Nr);
%        win_rng =Xcube(:,i,j);
       Rangedata(:,i,j)=fft(win_rng,fft_Rang);
    end
end
%% Second fft on dopper dimension
for i=1:Ne
    for j=1:fft_Rang
       win_dop =reshape(Rangedata(j,i,:),Nd,1).* 1;%hann(Nd);
       DopData(j,i,:)=fftshift(fft(win_dop,fft_Vel));
     end
end
%% 3DFFT
win = taylorwin(Ne,5,-60);
win = win/norm(win);
for j=1:fft_Rang
 for i=1:fft_Vel
    win_Ang =reshape(DopData(j,:,i),Ne,1).*1;%win;    
    AngData(j,:,i)=fftshift(fft(win_Ang,fft_Ang));
 end
end 
end

