% B2
%% A version of experiment using unilateral laser stimulation to check if 
% it can bias the choice of the mouse between left or rig
% ht water ports.
% This modification has forced alternating choice between the sides, i. e.
% the mouse has to get a reward from a certain port before it can get the
% next one. 
% Laser stimulation is applied on half trials, 25% of left and right trials
% overall
% Need to explain better
% Adding some comment buffer  so that there is less risk of accidentally
% typing somthing and disrupting the code
%
% wow green text
%
%
%
%
%
%
%
%
% does anyone even read comments? ... no :) haha
%
% In case there is an erroneaus restart, save all the variables
warning('off', 'raspi:utils:SaveNotSupported')
save(['D:\dual_lick\backup\' datestr(now,'yyyy-mm-dd-_HH_MM_SS') '.mat']);
% clear variables; 
close all;
mouse_id = input('Mouse id\n:'); 
laser_intensity = 22; % input('Laser intensity:\n');
laser_duration = [5, 45, 200]; % input('Laser duration:\n');
weight = input(['Mouse ' num2str(mouse_id) ' weight \n:']);
pre_note = input("Anything special before the experiment? \n:", "s");
tr_per_cond = 50; 50; % total number will be x8
training_type = 'B2';
%% Set up raspberry pi
rasp_init;

%

%% Sequence of stimulation
left = 1; right = -1;
seq_laser = repmat([zeros(1,4) left left right right ], 1, tr_per_cond)';
seq_side = repmat([left right], 1, tr_per_cond*4)';
tr_total = length(seq_laser);
permut_order = randperm(tr_total);
seq_laser = seq_laser(permut_order);
seq_side = seq_side(permut_order);

%% Variables to help out the poor mousie
max_missed = 7; freebie_skip = 4;

%% Stats tracking variables
choice = zeros(tr_total,1);
missed_trials = false(tr_total,1);
freebie = zeros(tr_total,1);
port_move_left = zeros(tr_total,1);

%% Durations of different states
dur_pre_laser = 2000;
dur_laser = 200; % duration of the laser stim before the response time
dur_after_go = 100;
dur_response = 1000;
dur_post_reward = 2500;
dur_jitter = 500;

%% State variables
LASER_PREP = 0;
PRE_LASER = 1;
LASER_STIM = 2;
PRE_RESP = 3;
AFTER_GO = 3.5;
RESPONSE = 4;
REWARD = 5;
POST_REWARD = 6;

state = LASER_PREP;



%% Time logging related variables
left_lick_times = zeros(10000,1); 
right_lick_times = zeros(10000,1); 
lick_n_L = 0;
lick_n_R= 0;

port_move_ts = zeros(tr_total,1);
resp_start_ts = zeros(tr_total,1);
laser_stim_ts = zeros(tr_total,1);
reward_ts = zeros(tr_total,1);

%% Variables for detecting licks
sens_buffer_len = 10;
lick_detected_left=0;
lick_detected_right=0;
sens_buffer_left = zeros(sens_buffer_len,1);
sens_buffer_right = zeros(sens_buffer_len,1);
sens_now_left = 0;
sens_now_right = 0;
sens_before_left = 0;
sens_before_right = 0;



%% Other variables
reward_dur_ms = 5;

%% Start the task
tr_current = 0;
tr_side = 1;
disp(['starting the task, time: ' datestr(now,'dd-mm-yyyy HH:MM:SS.FFF')]);
% Start the task
% training_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
%                 'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

time_stim_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
training_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
pin_ca_imaging = 21; %%
send_rasp_pulse(mypi, pin_ca_imaging, 5);
lfg = true;
%give_freebies(2, 3, mypi);
%% Run behavioral loop
while lfg

    %% detect lick
    scr_detect_lick;

    if state == LASER_PREP
        

        tr_current = tr_current + 1; % trial counter

        if tr_current == tr_total+1
            lfg = false; % prob not even needed
            break
        end
        % Change the position of the servo openers according to the current 
        % condition
        if seq_laser(tr_current) == 0
            disp('no laser');
            writePosition(servo_las_L,servo_las_closed_L);
            writePosition(servo_las_R,servo_las_closed_R);

        elseif seq_laser(tr_current) == left
            disp('left laser');
            writePosition(servo_las_L,servo_las_open_L);
            writePosition(servo_las_R,servo_las_closed_R);

        elseif seq_laser(tr_current) == right
            disp('right laser');
            writePosition(servo_las_L,servo_las_closed_L);
            writePosition(servo_las_R,servo_las_open_R);
        end

      

%         % Also, why don't we plot everything here: LATER ADD
%         if tr_current > 10
%             last_10_missed = missed_trials(tr_current-10:tr_current-1);
% 
%             
%         end


        % Start the timing for the pre-response time buffer
        state = PRE_LASER;
        pre_laser_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        

    elseif state == PRE_LASER
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

        if milliseconds(time_now - pre_laser_start) >= dur_pre_laser + randi(dur_jitter)
            state = LASER_STIM;
%             if tr_current ~= 1
%                 PsychPortAudio('Stop', pa_go);
%             end
        end

    elseif state == LASER_STIM
        % In this state, signal sent to Arduino to activate the laser
        laser_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        laser_stim_ts(tr_current) = milliseconds(laser_t - training_start);
        % Blast the laser for Arch
        send_rasp_pulse(mypi, pin_laser, 1);
        state = PRE_RESP;

    elseif state == PRE_RESP
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        if milliseconds(time_now - laser_t) >= dur_laser 
            state = AFTER_GO;
        time_go = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        send_rasp_pulse(mypi, pin_tone_go, 1);
            % PsychPortAudio('Start', pa_go, 1, 0, 0);
        end

    elseif state == AFTER_GO
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        if milliseconds(time_now - time_go) >= dur_after_go 
            state = RESPONSE;
            response_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            resp_start_ts(tr_current) = milliseconds(response_start - training_start);
        end
        

    elseif state == RESPONSE
        % Once the time for response runs out --> missed trial
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

            if lick_detected_left && seq_side(tr_current) == left
                choice(tr_current) = left;
                disp(['tr #' num2str(tr_current) ', choice: left']);
                state=REWARD;
                

            elseif lick_detected_right && seq_side(tr_current) == right
                choice(tr_current) = right;
                disp(['tr #' num2str(tr_current) ', choice: right']);
                state=REWARD;
            
%             elseif lick_detected_right && seq_side(tr_current) == left
%                 choice(tr_current) = right;
%                 disp(['tr #' num2str(tr_current) ', wrong choice: right']);
%                 state=LASER_PREP;
% 
%             elseif lick_detected_left && seq_side(tr_current) == right
%                 choice(tr_current) = left;
%                 disp(['tr #' num2str(tr_current) ', wrong choice: left']);
%                 state=LASER_PREP;

        
            elseif milliseconds(time_now - response_start) >= dur_response 
                state = LASER_PREP;
                missed_trials(tr_current) = true;
                disp(['tr #' num2str(tr_current) ', missed']);
                % Check if too many missed, give a freebie
                if tr_current > max_missed && ...
                    sum(missed_trials(tr_current-max_missed+1:tr_current)) >= max_missed ...
                    && sum(freebie(tr_current-freebie_skip:tr_current-1)) == 0
                    freebie(tr_current) = 1;
                    if seq_side(tr_current) == left
                        choice(tr_current) = left;
                    elseif seq_side(tr_current) == right
                        choice(tr_current) = right;
                    end
                    disp('freebie')
                    state=REWARD;
                end
                
            
            end


    elseif state == REWARD
        tr_side = tr_side + 1;
        reward_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        reward_ts (tr_current) = milliseconds(reward_t - training_start);
        reward_dur_ms=10;
        if choice(tr_current) == left 
%             send_rasp_pulse(mypi, pin_valv_left, 10);
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
%             if ~freebie(tr_current)
%                 pause(.1);
%                 writeDigitalPin(mypi,pin_valv_left,1);
%                 pause(reward_dur_ms*.001);
%                 writeDigitalPin(mypi,pin_valv_left,0);

%             end
            disp(['tr #' num2str(tr_current) ', reward left']);

        elseif choice(tr_current) == right 
%             send_rasp_pulse(mypi, pin_valv_right, 10);
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
%             if ~freebie(tr_current)
%                 pause(.1);
%                 writeDigitalPin(mypi,pin_valv_right,1);
%                 pause(reward_dur_ms*.001);
%                 writeDigitalPin(mypi,pin_valv_right,0);
%             end
            disp(['tr #' num2str(tr_current) ', reward right']);
        else
            disp('wtf');
        end

        state = POST_REWARD;
            

    elseif state == POST_REWARD
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

        if milliseconds(time_now - reward_t) >= dur_post_reward
            state = LASER_PREP;
        end
    end


end
%% Initializing sounds
sound_init;
% % Play end tone & close the audio device:
sound_end;

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
writematrix(right_lick_times, ['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_t_licks_R_'  datestr(now,'dd-mm-yyyy_HH-MM')  '.csv']);
writematrix(left_lick_times, ['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_t_licks_L_'  datestr(now,'dd-mm-yyyy_HH-MM')  '.csv']);

% Save other relevant info to .mat file
save(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_B1bias.mat'], ...
    'laser_intensity', 'laser_duration', 'training_start',...
   'left_lick_times','right_lick_times', 'weight');

training_end = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
training_duration = training_end - training_start;
disp(['training duration: ' datestr(training_duration,'HH:MM:SS.FFF')]);
save_behav_all;
