clc
clear all
close all

training_set = [12,13,14,21,22,23,24,30,31,33,34,35,36,40];
testing_set = [11,20,32];

ground_truth_Y_training = [0,-1,1,-0.5,0.5,-1,1,0,-0.5,-1,1,-1.5,1.5,0]; % angle
ground_truth_Y_testing = [-0.5,0,0.5];
ground_truth_X_training = [8,8,8,10,10,10,10,12,12,12,12,12,12,14]; %range
ground_truth_X_testing = [8,10,12];
% % calculated bias
% Y_bias = 0.1866;
% X_bias = -0.0513;
%%% training calculate the error and mean error
Y_bias = 0.1922;
X_bias = -0.0370;
for i=1:length(training_set)
    % load data
    eval(['temp = load(''D:\Documents\MATLAB\radar_test_network\radar_test_network\locs\obj_00',num2str(training_set(i)),'.txt'');']);
    temp = temp.';
    ran_data(i,:) = temp(1,:);
    ang_data(i,:) = temp(2,:);
    
    % coordinate transform
    [X_data(i,:),Y_data(i,:)] = pol2cart(temp(2,:)/180*pi,temp(1,:));
    Y_data(i,:) = Y_data(i,:)+7.62/100; % Y parallel to board, X parallel to line of sight
%     % compensate bias Y_bias = 0.1866, X_bias = -0.0513
%     Y_data(i,:) = Y_data(i,:)-Y_bias;
%     X_data(i,:) = X_data(i,:)-X_bias;

    bias_Y(i,:) = Y_data(i,:)-ground_truth_Y_training(i)*ones(1,10);
    bias_X(i,:) = X_data(i,:)-ground_truth_X_training(i)*ones(1,10);
%     [DataTh(i,:),DataR(i,:)] = cart2pol(X_data(i,:),Y_data(i,:));
end

bias_Y_new = reshape(bias_Y,1,size(bias_Y,1)*size(bias_Y,2));
bias_Y_mean = mean(bias_Y_new)
bias_X_new = reshape(bias_X,1,size(bias_X,1)*size(bias_X,2));
bias_X_mean = mean(bias_X_new)

%%% testing calibration

% for i=1:length(testing_set)
%     % load data
%     eval(['temp = load(''D:\Documents\MATLAB\radar_test_network\radar_test_network\locs\obj_00',num2str(testing_set(i)),'.txt'');']);
%     temp = temp.';
%     ran_data(i,:) = temp(1,:);
%     ang_data(i,:) = temp(2,:);
%     
%     % coordinate transform
%     [X_data(i,:),Y_data(i,:)] = pol2cart(temp(2,:)/180*pi,temp(1,:));
%     Y_data(i,:) = Y_data(i,:)+7.62/100; % Y parallel to board, X parallel to line of sight
%     % compensate bias Y_bias = 0.1922, X_bias = -0.0370
%     Y_data(i,:) = Y_data(i,:)-Y_bias;
%     X_data(i,:) = X_data(i,:)-X_bias;
% 
%     bias_Y(i,:) = Y_data(i,:)-ground_truth_Y_testing(i)*ones(1,10);
%     bias_X(i,:) = X_data(i,:)-ground_truth_X_testing(i)*ones(1,10);
%     [DataTh(i,:),DataR(i,:)] = cart2pol(X_data(i,:),Y_data(i,:));
% end
