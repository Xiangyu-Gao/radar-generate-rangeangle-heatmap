% plot the range-doppler heatmap for antenna 1
function [axh] = plot_rangeDop(Dopdata_chirp1,vel_grid,rng_grid)
% figure('visible','off')
figure()
set(gcf,'Position',[10,10,530,420])
[axh] = surf(vel_grid,rng_grid,20*log2(abs(squeeze(Dopdata_chirp1(:,1,:)))));
view(0,90)
axis([-8,8,0,28])
grid off
shading interp
title('Range-Velocity plot')
xlabel('Velocity')
ylabel('Range')
colorbar
caxis([0,300])
end