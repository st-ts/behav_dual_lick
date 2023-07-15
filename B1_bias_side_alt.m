%% A version of experiment using unilateral laser stimulation to check if 
% it can bias the choice of the mouse between left or right water ports.
% This modification has forced alternating choice between the sides, i. e.
% the mouse has to get a reward from a certain port before it can get the
% next one. Need to explain better

clear variables; close all;

mouse_id = input('Mouse id\n:'); 
tr_per_cond = 3; % total number will be x cond_mult, currently 4

%% Sequence of stimulation
left = 1; right = -1;
seq_laser = repmat([0 0 0 0 left left right right ], 1, tr_per_cond)';
seq_side = repmat([left right], 1, tr_per_cond*4)';
tr_total = length(seq_laser);
permut_order = randperm(tr_total);
seq_laser = seq_laser(permut_order);
seq_side = seq_cide(permut_order);

%% Variables to help out the poor mousie
max_missed = 

%% Stats tracking variables
choice = zeros(tr_total,1);
missed_trials = zeros(tr_total,1);
freebie = zeros(tr_total,1);
port_move_left = zeros(tr_total,1);

%% Durations of different states
dur_pre_laser = 1000;
dur_laser = 2000; % duration of the laser stim before the response time
dur_response = 1500;
dur_post_reward = 2500;
dur_jitter = 200;

%% State variables
LASER_PREP = 0;
PRE_LASER = 1;
LASER_STIM = 2;
PRE_RESP = 3;
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

%% Stepper
ardu = arduino('COM5','Uno','Libraries','Adafruit\MotorShieldV2');
shield = addon(ardu,'Adafruit\MotorShieldV2');
addrs = scanI2CBus(ardu,0);

stepper_lr = stepper(shield,1,200);
stepper_lr.RPM = 200;
stepper_lr_steps = 400; % Size of a step
stepped_left = 0; too_left = 2000; too_right = - 2000; % find out empiricaylly

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

%% Set up raspberry pi
rasp_init;

%% Other variables
reward_dur_ms = 5;

%% Start the task
tr_current = 0;
disp(['starting the task, time: ' datestr(now,'dd-mm-yyyy HH:MM:SS.FFF')]);
% Start the task
training_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

lfg = 1;

%% Run behavioral loop
while lfg

    %% detect lick
    scr_detect_lick;

    if state == LASER_PREP
        

        tr_current = tr_current + 1; % trial counter

        if tr_current == tr_total+1
            lfg = 0;
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

        % Move waterports to counteract the bias
%         if tr_current > max_conseq_to_move
%             % If too many consecuttive right trials, move left port closer
%             if sum(choice(tr_current - max_conseq_to_move : tr_current-1)) <= - max_conseq_to_move && ...
%                     stepped_left > too_right && ~missed_trials(tr_current - 1)
%                 move(stepper_lr, - stepper_lr_steps); release(stepper_lr);                
%                 stepped_left = stepped_left - stepper_lr_steps;
%                 disp(['left port closer: ' num2str(stepped_left)]);
%                 port_move_left(tr_current) = - 1;
%                 time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
%                 'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
%                 port_move_ts (tr_current) = milliseconds(time_now - training_start);
%             % Same for right port
%             elseif sum(choice(tr_current - max_conseq_to_move : tr_current-1)) >= max_conseq_to_move && ...
%                     stepped_left > too_left && ~missed_trials(tr_current - 1)
%                 move(stepper_lr, stepper_lr_steps); release(stepper_lr);                
%                 stepped_left = stepped_left + stepper_lr_steps;
%                 disp(['right port closer: ' num2str(stepped_left)]);
%                 port_move_left(tr_current) = 1;
%                 time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
%                 'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
%                 port_move_ts (tr_current) = milliseconds(time_now - training_start);
%             end
            % Set enforcement to only be able to pick 1 side if too biased
            if tr_current > max_conseq_to_force
                % if too many rights, forced to left
                if sum(choice(tr_current - max_conseq_to_force : tr_current-1)) <= - max_conseq_to_force
                    forced(tr_current) = left;
                    enforce = left;
                    disp('left enforced');
                % vice versa
                elseif sum(choice(tr_current - max_conseq_to_force : tr_current-1)) >= max_conseq_to_force
                    forced(tr_current) = right;
                    enforce = right;
                    disp('right enforced');
                end
                
%             end

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
        end

    elseif state == LASER_STIM
        laser_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        laser_stim_ts(tr_current) = milliseconds(laser_t - training_start);
        % Blast the laser for Arch
        writeDigitalPin(mypi,pin_laser,1);
        pause(0.05);
        writeDigitalPin(mypi,pin_laser,0);
        state = PRE_RESP;

    elseif state == PRE_RESP
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        if milliseconds(time_now - laser_t) >= dur_laser
            state = RESPONSE;
            response_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            resp_start_ts(tr_current) = milliseconds(response_start - training_start);
        end

    elseif state == RESPONSE
            if lick_detected_left && enforce ~= right
                choice(tr_current) = left;
                disp(['tr #' num2str(tr_current) ', choice: left']);
                if enforce == left
                    enforce = 0;
                end
                state=REWARD;
            elseif lick_detected_right && enforce ~= left
                choice(tr_current) = right;
                disp(['tr #' num2str(tr_current) ', choice: right']);
                if enforce == right
                    enforce = 0;
                end
                state=REWARD;
            end
        
        % Once the time for response runs out --> missed trial
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        if milliseconds(time_now - response_start) >= dur_response 
            state = LASER_PREP;
            missed_trials(tr_current) = 1;
            disp(['tr #' num2str(tr_current) ', missed']);
            % Check if too many missed, give a freebie
            if tr_current > max_missed && sum(missed_trials(tr_current-max_missed+1:tr_current)) >= max_missed
                if (sum(choice) < 0 && enforce ~= right) || enforce == left
                    freebie(tr_current) = left;
                elseif (sum(choice) > 0  && enforce ~= left) || enforce == right
                    freebie(tr_current) = right;
                elseif sum(choice) == 0
                    freebie(tr_current) = randsample([left right], 1);
                end
                disp('freebie')
                state=REWARD;
            end
        end


    elseif state == REWARD
        reward_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        reward_ts (tr_current) = milliseconds(reward_t - training_start);
        
        if choice(tr_current) == left || freebie(tr_current) == left
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
            pause(.1);
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
            disp(['tr #' num2str(tr_current) ', reward left']);

        elseif choice(tr_current) == right || freebie(tr_current) == right
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
            pause(.1);
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
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


% Make table with results
results_table = table(missed_trials, seq_laser, choice, freebie, forced, resp_start_ts, ...
        reward_ts, laser_stim_ts,...
        'VariableNames', {'missed', 'laser', 'choice', 'free', 'forced', 'resp_start_ts', ...
        'reward_ts', 'laser_stim_ts' ...
        });
disp(results_table);
% Tuncate the lick data
right_lick_times = right_lick_times(1:lick_n_R);
left_lick_times = left_lick_times(1:lick_n_L);


writetable(results_table, ['os_data_figs/os' num2str(mouse_id)  '/os' num2str(mouse_id) '_laser_bias_'  datestr(now,'dd-mm-yyyy_HH-MM') '.csv']);
writematrix(right_lick_times, ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_t_licks_R_'  datestr(now,'dd-mm-yyyy_HH-MM')  '.csv']);
writematrix(left_lick_times, ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_t_licks_L_'  datestr(now,'dd-mm-yyyy_HH-MM')  '.csv']);

training_end = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
training_duration = training_end - training_start;
disp(['training duration: ' datestr(training_duration,'HH:MM:SS.FFF')]);
