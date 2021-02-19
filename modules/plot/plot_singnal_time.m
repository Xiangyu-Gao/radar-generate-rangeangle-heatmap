function [] = plot_singnal_time(Xcube)
figure()
plot(abs(Xcube(:,1,1)))
xlabel('time')
ylabel('Amplitude')
end