function [DopData AngData Rangedata]=fft_Radar(Xcube,fft_Rang,fft_Vel,fft_Ang)
%%%%  Xcube : Nr*Ne*Nd , original data
%%%   fft_Rang: range fft length
%%%   fft_Vel:  velocity fft length(2D-FFT)
%%%   fft_Ang:  angle fft length(3D FFT)
%%
Nr=size(Xcube,1);   %%%length of Chirp
Ne=size(Xcube,2);   %%%length of receiver
Nd=size(Xcube,3);   %%%length of chirp loop

%%% Range fft
for i=1:Ne
    for j=1:Nd
        win_rng =Xcube(:,i,j).*1;% hann(Nr);
        Rangedata(:,i,j)=fftshift(fft(win_rng,fft_Rang));
    end
end
%%% Second fft on dopper dimension
for i=1:Ne
    for j=1:fft_Rang
        win_dop =reshape(Rangedata(j,i,:),Nd,1).*1;% hann(Nd);
        DopData(j,i,:)=fftshift(fft(win_dop,fft_Vel));
    end
end
figure()
mesh(squeeze(abs(DopData(:,1,:))))
title('Range-doppler plot for Rx1')
view(0,90)
win = taylorwin(Ne,5,-60);
win = win/norm(win);

[hhh,iii] = max(Rangedata(:,1,1));
antenna_data=DopData(iii,:,65);%%%
angle_comp=(unwrap(angle(antenna_data)));
angle_comp(5:8)=angle_comp(5:8);%+2*pi;
x_lab1=[1:4];
y_lab1=angle_comp(1:4);
p1 = polyfit(x_lab1,y_lab1,1)%%ÄâºÏ
x_lab1=[1:4];
y_lab1=angle_comp(1:4);
x_lab2=[5:8];
y_lab2=angle_comp(5:8);

figure()
p2= polyfit(x_lab2,y_lab2,1)
deviation1=p1(1)*x_lab1+p1(2)-y_lab1;
deviation2=p2(1)*x_lab2+p2(2)-y_lab2;

temp=p1(2)-p2(2);
% p2(2)=p1(2);
plot(x_lab1,y_lab1,'ob',x_lab1,polyval(p1,x_lab1))
hold on
plot(x_lab2,y_lab2,'or',x_lab2,polyval(p2,x_lab2))
axis([0 10 -25 25])
xlabel('Virtual Channel Index ');
ylabel('unwrapped phase(rad)');
legend('Tx1-phase','Tx1-phase-interpolation','Tx2-phase','Tx2-phase-interpolation')
title('Target')

antenna_data(5:8)=antenna_data(5:8)*exp(j*temp);
angle_comp1=unwrap(angle(antenna_data));
figure()
plot(angle_comp1)
hold on
plot(angle_comp,'r')
legend('Compensation','Origin')
figure()
plot([1:4],angle_comp(1:4),'.-');
hold on
plot([5:8],angle_comp(5:8),'.-r');
xlabel('Virtual Channel Index ');
ylabel('unwrapped phase(rad)');
legend('Tx1','Tx2')
title('Original Phase')
axis([0 10 -25 25])
for j=1:fft_Rang
    for i=1:fft_Vel
        win_Ang =reshape(DopData(j,:,i),Ne,1).*win;
        win_Ang(5:8)=win_Ang(5:8)*exp(sqrt(-1)*temp);
        AngData(j,:,i)=fftshift(fft(win_Ang,fft_Ang));
    end
end
end

