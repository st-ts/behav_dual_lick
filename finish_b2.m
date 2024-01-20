% Make table with results
results_table = table(missed_trials, seq_laser, choice, freebie, resp_start_ts, ...
        reward_ts, laser_stim_ts,...
        'VariableNames', {'missed', 'laser', 'choice', 'free', 'resp_start_ts', ...
        'reward_ts', 'laser_stim_ts' ...
        });
% disp(results_table);
% Tuncate the lick data
right_lick_times = right_lick_times(1:lick_n_R);
left_lick_times = left_lick_times(1:lick_n_L);


writetable(results_table, ['D:/dual_lick/os_data_figs/os' num2str(mouse_id)  '/os' num2str(mouse_id) '_laser_bias_'  datestr(now,'dd-mm-yyyy_HH-MM') '.csv']);
if lick_n_R>0
    writematrix(right_lick_times, ['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_t_licks_R_'  datestr(now,'dd-mm-yyyy_HH-MM')  '.csv']);
end
if lick_n_L>0
writematrix(left_lick_times, ['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_t_licks_L_'  datestr(now,'dd-mm-yyyy_HH-MM')  '.csv']);
end
% Save other relevant info to .mat file
save(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_B1bias.mat'], ...
    'laser_intensity', 'laser_duration', 'training_start',...
   'left_lick_times','right_lick_times', 'weight');

training_end = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
training_duration = training_end - training_start;
disp(['training duration: ' datestr(training_duration,'HH:MM:SS.FFF')]);
save_behav_all;