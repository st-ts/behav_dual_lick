% For the dual lick working memory experiment
% 3rd stage of training
% After licking any port, go cue sounds and water is provided

% In case there is an erroneaus restart, save all the variables
save(['D:\dual_lick\backup\' datestr(now) '.mat']);
%% Clear and close all
close all; clear variables; format compact;

%% Important parameters to set up
mouse_id = input('Mouse id\n:'); 

% Set the number of trials
tr_per_cond_max = 35; % total 6 conditions, n of trials x 10

% Help the poor mousie
freebie = 1; freebie_n = 0; freebie_max = 200; missed_till_freebie = 4;
max_wrong = 2; 
port_lr_move = 1;

n_trials= 500; % 

pre_tone_delay_dur=2500; % in milliseconds
response_dur = 2000; 
reward_dur_ms = 5;

% Load & set the training stage data
load(['os_data_figs/os' num2str(mouse_id) '/reference_oscc' num2str(mouse_id) '.mat']);
choice_punish_time_out_dur = 0;

max_tone_n = 2000;

%% Initializing sounds
sound_init;

%% Time logging related variables
left_lick_times = [];
right_lick_times = [];
amb_tone_times = zeros(1,max_tone_n);
right_tone_times = zeros(1,max_tone_n);
tone_times = zeros(1, max_tone_n);
current_waits = zeros(1,n_trials);
trial_order = ones(1,max_tone_n)*3;
free = ones(1,max_tone_n)*3;
switch_max = 5;
switch_cond = randi([1,switch_max],1,1);

%% Set up raspberry pi
rasp_init;

%% Set the order of conditions

permut_order = randperm(tr_per_cond_max*10);
seq_laser = repmat([0 0 0 0 0 0 1 1 2 2], 1, tr_per_cond_max);
seq_side =  repmat([1 -1], 1, tr_per_cond_max*5);
seq_laser = seq_laser(permut_order);
seq_side = seq_side(permut_order);
max_tries = length(seq_laser);
trials_total = length(seq_laser);

%% Variables for detecting licks
sens_buffer_len = 10;
lick_detected_left=0;
lick_detected_right=0;
lick_n_L = 0;
lick_n_R= 0;
sens_buffer_left = zeros(sens_buffer_len,1);
sens_buffer_right = zeros(sens_buffer_len,1);
sens_now_left = 0;
sens_now_right = 0;
sens_before_left = 0;
sens_before_right = 0;

%% Stats tracking variables
tone_n=0;
early_lick_trials_delay = ones(1,max_tone_n)*3;
missed_trials = ones(1,max_tone_n)*3; % 1 if missed, 0 otherwise
left_trial_correct = []; % 1 if correct, 0 if right is chosen instead of left
right_trial_correct = []; % otherwise 
choice_made = ones(1,max_tone_n);
max_tr_missed = 15;
too_many_tr_missed=0;

%% State related variables
TONE = 1;
RESPONSE = 2;
GO_CUE = 3;
REWARD = 4;
PRE_TONE_DELAY = 5;
LASER_PREP = 6;
WAIT_PUNISHMENT_TIME_OUT = 7;
CHOICE_PUNISHMENT_TIME_OUT = 8;
FIRST_TRIAL = 9;
REWARD_INTAKE = 10;

state=FIRST_TRIAL;

% Reward-related
left=1; right=-1;

%% Ask about training info
weight = input(['Mouse ' num2str(mouse_id) ' weight \n:']);
pre_note = input("Anything special before the experiment? \n:", "s");


%% Stepper
ardu = arduino('COM5','Uno','Libraries','Adafruit\MotorShieldV2');
shield = addon(ardu,'Adafruit\MotorShieldV2');
addrs = scanI2CBus(ardu,0);

stepper_lr = stepper(shield,1,200);
stepper_lr.RPM = 200;
stepper_lr_steps = 100; % 
stepped_left = 0; too_left = 2000; too_right = - 2000; % find out empiricaylly
side_wrong_to_step = 5;

port_move_back = zeros(1,max_tone_n);
port_move_left = zeros(1,max_tone_n);

%% Start the task
n=0;
disp(['starting the task, time: ' datestr(now,'dd-mm-yyyy HH:MM:SS.FFF')]);
% Start the task
training_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

too_long = 0;

pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
% Figure setup
set(0,'DefaultFigureWindowStyle','docked')
figure(1); hold on; ylim([-0.2 11])
% plot(1, 1,'ro'); % early abs
plot(1, 1,'k*'); % early
plot(1, 1,'ro'); % missed
plot(1, 1,'b*'); % right correct
plot(1, 1,'g*'); % left correct
legend( 'early', 'missed', 'correct right', 'correct left', ...
        'AutoUpdate', 'off', "Location", "northwest");
set(gca,'YGrid', 'on', 'XGrid', 'off');
% set(gcf, 'Position', [0,960,1700, 380])
% To make sure there's no sudden flash at the beginning
writeDigitalPin(mypi,pin_valv_right,0);
writeDigitalPin(mypi,pin_valv_right,0);
%     
writeDigitalPin(mypi,pin_valv_left,0);
writeDigitalPin(mypi,pin_valv_left,0);


if seq_laser(tone_n+1) == 0
    writePosition(servo_las_L,servo_las_closed_L);
    writePosition(servo_las_R,servo_las_closed_R);
    disp('no laser');
elseif seq_laser(tone_n+1) == 1
    writePosition(servo_las_L,servo_las_open_L);
    writePosition(servo_las_R,servo_las_closed_R);
    disp('left laser');
elseif seq_laser(tone_n+1) == 2
    writePosition(servo_las_L,servo_las_closed_L);
    writePosition(servo_las_R,servo_las_open_R);
    disp('right laser');
end


% writePosition(serv,servo_away);
while ( n < n_trials ) 

    %% Detect lick
    scr_detect_lick;

    %% 1st trial to begin
    if state == FIRST_TRIAL
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

        % When delay is over, transition to sound and start the tone
        if milliseconds(time_now-pre_tone_delay_start)>=pre_tone_delay_dur
            state=TONE;
            tone_n=tone_n+1;

        % Blast the laser for Arch
        writeDigitalPin(mypi,pin_laser,1);
        pause(0.01);
        writeDigitalPin(mypi,pin_laser,0);



        % Play the tone according to the condition
        current_cond=seq_side(tone_n);
        PsychPortAudio('Start', pa_ambig, 1, 0, 0);
        tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
        'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        amb_tone_times(tone_n) = milliseconds(training_start-tone_start);
        tone_times(tone_n) = milliseconds(training_start-tone_start);
        end
    end
    

    %% Prepare the servos before the pretone delay
    if state == LASER_PREP
        tone_n=tone_n+1;
        if tone_n > trials_total
                tone_n = tone_n-1;
                break
        end
    % Set the laser open/close status depending on the trial type
        if seq_laser(tone_n) == 0
            disp('no laser');
            writePosition(servo_las_L,servo_las_closed_L);
            writePosition(servo_las_R,servo_las_closed_R);
        elseif seq_laser(tone_n) == 1
            disp('left laser');
            writePosition(servo_las_L,servo_las_open_L);
            writePosition(servo_las_R,servo_las_closed_R);
        elseif seq_laser(tone_n) == 2
            disp('right laser');
            writePosition(servo_las_L,servo_las_closed_L);
            writePosition(servo_las_R,servo_las_open_R);
        end
        state = PRE_TONE_DELAY;

    end
    
    %% Pre-tone delay
    if state == PRE_TONE_DELAY
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        
        % Check if the traibibg goes for too long
        if minutes(time_now-training_start) > train_t_max
            too_long= 1;
        end

        % When delay is over, transition to sound and start the tone
        if milliseconds(time_now-pre_tone_delay_start)>=pre_tone_delay_dur+randi(1000)
            state=TONE;
            
            left_trial_correct_nonan = left_trial_correct (~isnan(left_trial_correct));
            right_trial_correct_nonan = right_trial_correct (~isnan(right_trial_correct));
            % Move the ports to the left / right if there are X wrong side
            %choices in a row
            if port_lr_move && length(left_trial_correct_nonan) >= side_wrong_to_step && ...
                    sum(left_trial_correct_nonan(end - side_wrong_to_step + 1:end)) < 0.1 ...
                    && stepped_left > too_right && ~missed_trials(tone_n-1)

                move(stepper_lr, - stepper_lr_steps); release(stepper_lr);                
                stepped_left = stepped_left - stepper_lr_steps;
                disp(['left port closer: ' num2str(stepped_left)]);
                port_move_left(tone_n+1) = - 1;
            end

            % Same for right
            if port_lr_move && length(right_trial_correct_nonan) >= side_wrong_to_step && ...
                    sum(right_trial_correct_nonan(end - side_wrong_to_step + 1:end)) < 0.1 ...
                    && stepped_left < too_left && ~missed_trials(tone_n-1)
               
                move(stepper_lr, stepper_lr_steps); release(stepper_lr);                
                stepped_left = stepped_left + stepper_lr_steps;
            
                disp(['right port closer: ' num2str(stepped_left)]);
                port_move_left(tone_n+1) = 1;
            end
        
        if tone_n > max_tries
            too_long= 1;
        else
        
            % Blast the laser for Arch
            writeDigitalPin(mypi,pin_laser,1);
            
            % Play the ambiguous tone
            current_cond=seq_side(tone_n);
            PsychPortAudio('Start', pa_ambig, 1, 0, 0);
            tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
            'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            amb_tone_times(tone_n) = milliseconds(training_start-tone_start);
            tone_times(tone_n) = milliseconds(training_start-tone_start);
    
            pause(0.01);
            writeDigitalPin(mypi,pin_laser,0);
        end
            
        end
    end
    
    %% Tone waiting out
    if state == TONE
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % After tone's time is over, stop it and transition to waiting for
        % licks
        if milliseconds(time_now - tone_start) >= 1150

            PsychPortAudio('Stop', pa_ambig);
            pause(0.05);
            PsychPortAudio('Start', pa_go, 1, 0, 0);
            response_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            state = RESPONSE;
        end
    end
    
    %% Waiting for licks
    if state == RESPONSE
        
        if (current_cond==left) && length(left_trial_correct)>=max_wrong && (sum(left_trial_correct(end-max_wrong+1:end)) == 0)
            disp('undeserved reward');
            free(tone_n) = 1;
            state=REWARD;
            left_trial_correct = [left_trial_correct 0.01];
            choice_made(tone_n) = 0;
            if length(left_trial_correct) >=10
                last_10_left_corr = sum( left_trial_correct(end-9:end) );
                plot(tone_n, last_10_left_corr-.1,'g*');
                xlim([0 tone_n+1]);
            end

            missed_trials(tone_n) = 0;
            if tone_n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
        end


    if (current_cond==right) && length(right_trial_correct)>max_wrong && (sum(right_trial_correct(end-max_wrong+1:end))  == 0)
            disp('undeserved reward');
            free(tone_n) = 1;
            state=REWARD;
            right_trial_correct = [right_trial_correct 0.01];
            choice_made(tone_n) = 0;
            if length(right_trial_correct) >=10
                last_10_right_corr = sum( right_trial_correct(end-9:end) );
                plot(tone_n, last_10_right_corr-.1,'b*');
                xlim([0 tone_n+1]);
            end
            missed_trials(tone_n) = 0;
            if tone_n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
        end


        if tone_n>=missed_till_freebie+1
            if freebie && sum(missed_trials(tone_n-1-(missed_till_freebie-1):tone_n-1))==missed_till_freebie && freebie_n < freebie_max
                state=REWARD;
                freebie_n = freebie_n+1;
                free(tone_n) = 2;
               missed_trials(tone_n) = 0;
                if tone_n >10
                    last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                    disp(['~~~ FREEBIE #' num2str(freebie_n) ' ~~~']);
                end
            end
        end
        
        if (current_cond==left) && (lick_detected_left==1)
            
            left_trial_correct = [left_trial_correct 1];
            choice_made(tone_n) = 1;
            if length(left_trial_correct) >=10
                last_10_left_corr = sum( left_trial_correct(end-9:end) );
                plot(tone_n, last_10_left_corr-.1,'g*');
                xlim([0 tone_n+1]);
            end
            state=REWARD;
            missed_trials(tone_n) = 0;
            if tone_n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
        elseif (current_cond==left) && (lick_detected_right==1)
            left_trial_correct = [left_trial_correct 0];
            choice_made(tone_n) = -1;
            if length(left_trial_correct) >=10
                last_10_left_corr = sum( left_trial_correct(end-9:end) );
                plot(tone_n, last_10_left_corr-.1,'g*');
                xlim([0 tone_n+1]);
            end
            missed_trials(tone_n) = 0;
            if tone_n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
            disp("licked right instead of left");
            
            state = CHOICE_PUNISHMENT_TIME_OUT;
            choice_punish_timeout_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        elseif (current_cond==right) && (lick_detected_right==1) 
            right_trial_correct = [right_trial_correct 1];
            choice_made(tone_n) = -1;
            if length(right_trial_correct) >=10
                last_10_right_corr = sum( right_trial_correct(end-9:end) );
                plot(tone_n, last_10_right_corr-.1,'b*');
                xlim([0 tone_n+1]);
            end
            state=REWARD;
            missed_trials(tone_n) = 0;
            if tone_n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
        elseif (current_cond==right) && (lick_detected_left==1)
            right_trial_correct = [right_trial_correct 0];
            choice_made(tone_n) = -1;
            if length(right_trial_correct) >=10
                last_10_right_corr = sum( right_trial_correct(end-9:end) );
                plot(tone_n, last_10_right_corr-.1,'b*');
                xlim([0 tone_n+1]);
            end
            missed_trials(tone_n) = 0;
            if tone_n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
            disp("licked left instead of right");
            
            state = CHOICE_PUNISHMENT_TIME_OUT;
            choice_punish_timeout_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
              'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        if milliseconds(time_now-response_start)>=response_dur
           missed_trials(tone_n) = 1;
            if tone_n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
            disp("missed trial");
            if tone_n >=max_tr_missed+2
                if sum(missed_trials(tone_n-max_tr_missed+1:tone_n))>=max_tr_missed
                    too_many_tr_missed=1;
                end
            end
%             writePosition(serv,servo_away);
            state = LASER_PREP;
            PsychPortAudio('Stop', pa_go);
            pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end

    end
    
    %% Choice punishment
    if state== CHOICE_PUNISHMENT_TIME_OUT
    
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                  'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % Move to the pre-tone delay after the timeout is over
        if milliseconds(time_now-choice_punish_timeout_start)>=choice_punish_time_out_dur
            state = LASER_PREP;
            PsychPortAudio('Stop', pa_go);
            pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end      

    end
    
    %% Reward
    if state == REWARD        
        n=n+1;

        cond_count=cond_count+1;
        if current_cond == left
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
            pause(.1);
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
            
            disp(['left reward given; trial #' num2str(n) ]); 
        else
 
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
            pause(.1);
            
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
            
            disp(['right t reward given; trial #' num2str(n) ]);  
        end


        PsychPortAudio('Stop', pa_go);
%         writePosition(serv,servo_away);
        state = LASER_PREP;
        pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

    end
    
end

% % Play end tone & close the audio device:
sound_end;

training_end = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

post_note = input("Anything special after the experiment? \n:", "s");
if ~exist(['os_data_figs/os' num2str(mouse_id) ], 'dir')
       mkdir()
    end
discr=1;

save(['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_B4.mat'], ...
    'missed_trials', 'choice_made', ...
    'left_trial_correct','right_trial_correct', 'training_start',...
    'left_lick_times','right_lick_times', ...
    'amb_tone_times','right_tone_times','trial_order', 'weight', 'discr', ...
    'pre_note', 'post_note', 'n', 'reward_alt',  'free');


% Truncate
missed_trials = missed_trials(1:tone_n-1)';
seq_laser = seq_laser(1:tone_n-1)';
seq_side = seq_side(1:tone_n-1)';
tone_times = tone_times(1:tone_n-1)';
choice = choice_made(1:tone_n-1)';
free = free(1:tone_n-1)';
port_move_left = port_move_left(1:tone_n-1)';

saveas(gcf, ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_B4.fig']);
saveas(gcf, ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_B4.jpg']);

% Save csv 
results_table = table(missed_trials, seq_laser, seq_side, tone_times, choice, free, port_move_left, ...
        'VariableNames', {'missed', 'laser', 'side', 'tone_ts', 'choice', 'free', 'port_move_left'});
writetable(results_table, ['os_data_figs/os' num2str(mouse_id)  '/os' num2str(mouse_id) '_laser_'  datestr(now,'dd-mm-yyyy_HH-MM') '.csv']);
writematrix(right_lick_times', ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_t_licks_R_'  datestr(now,'dd-mm-yyyy_HH-MM')  '.csv']);
writematrix(left_lick_times', ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_t_licks_L_'  datestr(now,'dd-mm-yyyy_HH-MM')  '.csv']);

correct_left = sum(left_trial_correct)/length(left_trial_correct)
correct_right = sum(right_trial_correct)/length(right_trial_correct)

training_duration = training_end - training_start;
disp(['training duration: ' datestr(training_duration,'HH:MM:SS.FFF')]);
% writePosition(serv,servo_near);
disp(['Mouse did ' num2str(n) ' trials']);