% plot the range-doppler heatmap for antenna 1
function [] = plot_rangeDop(Dopdata_chirp1,vel_grid,rng_grid)
figure()
mesh(vel_grid,rng_grid,abs(squeeze(Dopdata_chirp1(:,1,:))));
view(0,90)
axis([-10,10,0,28])
title('Range-doppler plot for Rx1')
xlabel('doppler')
ylabel('Range')
end