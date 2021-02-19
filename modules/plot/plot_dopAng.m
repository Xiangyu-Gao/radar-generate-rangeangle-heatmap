% plot the range-doppler heatmap for antenna 1
function [axh] = plot_dopAng(Dopdata_chirp1,vel_grid,ang_grid)
% figure('visible','off')
figure()
set(gcf,'Position',[10,10,530,420])
[axh] = surf(vel_grid,ang_grid,squeeze(20*log2(sum(abs(Dopdata_chirp1),1))));
view(0,90)
axis([-8,8,-90,90])
grid off
shading interp
title('Angle-Velocity plot')
xlabel('Velocity')
ylabel('Angle')
colorbar
caxis([0,300])
end