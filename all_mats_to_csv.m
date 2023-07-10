%% Script that should work for all mat files for behavior and caim
clear variables;
mouse_id = 652;

%% Load neural + behav data + quality of neurons .mat file
exp_type = 'ambig';
path = ['D:\CaIm\' exp_type '\os' num2str(mouse_id) '\'];
load([path 'os' num2str(mouse_id) '_' exp_type  '_behav.mat']);
load([path 'os' num2str(mouse_id) '_' exp_type ' _data_processed.mat'], ...
    'sigfn', 'spkfn', 'dff');
load([path 'os' num2str(mouse_id) '_' exp_type '_neu_qual.mat'])

% All the neural data to csv
writematrix(sigfn', [path 'os' num2str(mouse_id) '_' exp_type '_sigfn.csv']);
% writematrix(dff, ['os' num2str(mouse_id) '_dff.csv']);
% writematrix(spkfn, ['os' num2str(mouse_id) '_spkfn.csv']);
% 
% All the behavioral data to csv as well
water_seq = water_seq(trial_order);
laser_stim_seq = laser_stim_seq(trial_order);

% Correct the timing to make everything zero to the CaIm start
load('D:\CaIm\timings_caim_behav.mat');




behav_trials = [water_seq' laser_stim_seq' t_port_move' t_stims'];
behav_trials = array2table(behav_trials);
behav_trials.Properties.VariableNames(1:4) = {'water_type', 'laser_type', 't_port_move', 't_stim'};

writetable(behav_trials, ['os' num2str(mouse_id) '_' exp_type '_behav.csv']);


writematrix(right_lick_times, ['os' num2str(mouse_id) '_t_licks_R.csv']);
writematrix(left_lick_times, ['os' num2str(mouse_id) '_t_licks_L.csv']);
writematrix(neu_qual, [path 'os' num2str(mouse_id) '_' exp_type '_neu_qual.csv']);


% % name = 'os064_21-04-2023_00-03';
% % writematrix(left_trial_correct, [name '_left_correct.csv']);
% % writematrix(right_trial_correct, [name '_right_correct.csv']);


% 
% 
% timings = [5440 3010 8630 14770];
% timings = array2table(timings);
% behav_trials.Properties.VariableNames(1:4) = {'blue', 'las1', 'las2', 'las3'};
% 
% writetable(timings, 'caim_behav_timing.csv');

