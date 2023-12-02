% Script for saving all the necessary data after a run

% Save all the mat files
% Make sure the folder for saving exists, if not --> create
if ~exist(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) ], 'dir')
       mkdir(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) ]);
end

current_date = datestr(now,'yy-mm-dd_HH-MM');
path_folder = ['D:/dual_lick/os_data_figs/os' num2str(mouse_id) ];
path_start = [path_folder '/os' num2str(mouse_id) '_' current_date '_' training_type ];
path_save_ref = [ path_folder '/reference_oscc' num2str(mouse_id) '.mat'];
path_save_data = [ path_start '.mat'];
 
if training_type == 'A1'
    save(path_save_data, ...
    'left_rew_times', 'right_rew__times', 'weight', 'freebie_n', ...
    'pre_note', 'post_note', 'weight_after');

    % Save csv 
    writematrix(right_lick_times', [ path_start  '_t_licks_R.csv']);
    writematrix(left_lick_times',  [ path_start  '_t_licks_L.csv']);

elseif training_type == 'A2' | training_type == 'A3'
    save(path_save_data, ...
    'missed_trials', 'left_trial_correct','right_trial_correct', 'training_start',...
    'left_lick_times','right_lick_times', 'discr',...
    'left_tone_times','right_tone_times','trial_order', 'weight', ...
    'pre_note', 'post_note', 'training_type', 'n', 'reward_alt', 'weight_after');

    save(path_save_ref, ...
    'missed_trials', 'left_trial_correct','right_trial_correct', 'reward_alt');

    % Save the figure
    saveas(gcf, [ path_start '.jpg'] ); % save figure

    % Save csv 
    results_table = table(missed_trials', left_trial_correct', right_trial_correct', ...
                          left_tone_times,  right_tone_times', trial_order', ...
         'VariableNames', {'missed', 'left_correct', 'right_correct', ...
                           'left_tone_t', 'right_tone_t', 'trial_order'});
    writetable(results_table,[ path_start  '.csv']);
    writematrix(right_lick_times', [ path_start  '_t_licks_R.csv']);
    writematrix(left_lick_times',  [ path_start  '_t_licks_L.csv']);

elseif training_type == 'B1'
    save([path_start '_lawa.mat'], ...
    't_stims', 't_port_move', ...
    'laser_stim_seq', 'water_seq',  'post_note', ...
    'left_lick_times', 'right_lick_times', ...
    'time_imag_start', 'laser_stim_param');

    % Save csv 
    results_table = table(laser_stim_seq', water_seq', t_stims', t_port_move',...
            'VariableNames', {'laser', 'port', 't_laser', 't_port'});
    writetable(results_table,[ path_start  '.csv']);
    
    writematrix(right_lick_times', [ path_start  '_t_licks_R.csv']);
    writematrix(left_lick_times',  [ path_start  '_t_licks_L.csv']);



end
