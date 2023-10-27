% Script for saving all the necessary data after a run

% Save all the mat files
% Make sure the folder for saving exists, if not --> create
if ~exist(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) ], 'dir')
       mkdir(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) ]);
end

path_save_ref = ['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/reference_oscc' num2str(mouse_id) '.mat'];
path_save_data = ['D:/dual_lick/os_data_figs/os' num2str(mouse_id) ...
    '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_A' num2str(training_stage) '.mat'];

if training_stage == 1
    save(path_save_data, ...
    'left_rew_times', 'right_rew__times', 'weight', 'freebie_n', ...
    'pre_note', 'post_note', 'weight_after');

elseif training_stage == 2
    save(path_save_data, ...
    'missed_trials', 'left_trial_correct','right_trial_correct', 'training_start',...
    'left_lick_times','right_lick_times',...
    'left_tone_times','right_tone_times','trial_order', 'weight', ...
    'pre_note', 'post_note', 'n', 'mouse3rew', 'weight_after');

elseif training_stage == 3
    save(path_save_data, ...
    'missed_trials', 'left_trial_correct','right_trial_correct', 'training_start',...
    'left_lick_times','right_lick_times', ...
    'left_tone_times','right_tone_times','trial_order', 'weight', 'discr', ...
    'pre_note', 'post_note', 'training_type', 'n', 'reward_alt', 'weight_after');
end
