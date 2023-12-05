% For the dual lick working memory experiment
% 3rd stage of training
% After licking any port, go cue sounds and water is provided

% In case there is an erroneaus restart, save all the variables
save(['D:\dual_lick\backup\' datestr(now) '.mat']);
%% Clear and close all
close all; clear variables; format compact;

%% Important parameters to set up
mouse_id = input('Mouse id\n:'); 
tr_per_cond_max = 1; % total n is x10, 6 conditions 

% Help the poor mousie
freebie = 1; freebie_n = 0; freebie_max = 6; missed_till_freebie = 5;
max_wrong = 4; 

n_trials= 350; % 
max_tries = ceil(n_trials*2);
imaged_trials = 100;
pre_tone_delay_dur=2000; % in milliseconds
response_dur = 1000; 
% Load the calibrated valves data
% load('reference_oscc4.mat');
% load('valves_calibrated.mat');

% Load & set the training stage data
load(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/reference_oscc' num2str(mouse_id) '.mat']);

reward_dur_ms = 20;

prev_correct_left = sum(left_trial_correct)/length(left_trial_correct);
prev_correct_right = sum(right_trial_correct)/length(right_trial_correct);
discrim=dprime(prev_correct_left,1-prev_correct_right);


% 
% 
% if reward_alt == 0
%     disp("random order as prev day");
% elseif discrim>1  & prev_correct_left>.55 & prev_correct_right > .55
%     reward_alt = 0;
%     disp(" new random order");
% else
%     reward_alt = 1;
%     disp("Rewards alternating");
% end

current_wait=0;

choice_punish_time_out_dur =1000;

% 
% if mouse_id > 42
%     mouse3rew = 1;
%      disp("3 rew alternating");
% else
%     mouse3rew = 0;
%     disp("random order");
%     choice_punish_time_out_dur =10000;
% end
    
wait_punish_time_out_dur = 800;

max_tone_n = 2000;

%% Initializing sounds
sound_init;


%% Time logging related variables
left_lick_times = [];
right_lick_times = [];
left_tone_times = zeros(1,max_tone_n);
right_tone_times = zeros(1,max_tone_n);
tone_times = zeros(1, max_tone_n);
current_waits = zeros(1,n_trials);
free = zeros(1,n_trials);
trial_order = ones(1,max_tone_n)*3;
switch_max = 5;
switch_cond = randi([1,switch_max],1,1);

%% Monitor anticipatory licking
anticip = [];
lick_1st = 1;

%% Set up raspberry pi
mypi = raspi('169.254.156.249', 'pi', 'raspberry');
load('reference_rasp.mat'); % file with all the pin numbers and values for servo open / close
% %  configure pins

configurePin(mypi,pin_sens_left,'DigitalInput');
configurePin(mypi,pin_sens_right,'DigitalInput');
configurePin(mypi,pin_valv_left,'DigitalOutput');
configurePin(mypi,pin_valv_right,'DigitalOutput');
configurePin(mypi,pin_ca_imaging,'DigitalOutput');
configurePin(mypi,pin_laser,'DigitalOutput');
serv = servo(mypi, pin_servo_water);
servo_las_L = servo(mypi, pin_servo_laser_L);
servo_las_R = servo(mypi, pin_servo_laser_R);



%% Temporary - to test servos for lasers  COMMENT OUT LATER!!!!1!!!!!1!!!!!

% for ept=1:10
%     writePosition(servo_las_L,servo_las_open_L);
%     writePosition(servo_las_R,servo_las_open_R);
%     pause(3);
%     writePosition(servo_las_L,servo_las_closed_L);
%     writePosition(servo_las_R,servo_las_closed_R);
%     pause(3);
% end
% writePosition(serv,servo_near);

%% Set the order of conditions


permut_order = randperm(tr_per_cond_max*10);

seq_laser = repmat([0 0 0 0 0 0 1 1 2 2], 1, tr_per_cond_max);
seq_side =  repmat([1 -1], 1, tr_per_cond_max*5);
seq_laser = seq_laser(permut_order);
seq_side = seq_side(permut_order);
trials_total = length(seq_side);

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
lick_n_L = 0;
lick_n_R = 0;

%% Stats tracking variables
% total_trials = [];

tone_n=0;
early_lick_trials_abs = ones(1,max_tone_n)*3; % 1 if early lick, 0 otherwise
early_lick_trials_delay = ones(1,max_tone_n)*3;
missed_trials = ones(1,max_tone_n)*3; % 1 if missed, 0 otherwise
left_trial_correct = []; % 1 if correct, 0 if right is chosen instead of left
right_trial_correct = []; % otherwise 
choice_made = zeros(1,max_tone_n);
max_tr_missed = 15;
too_many_tr_missed=0;

%% Increment related variebles
early_lick = [];
last_10_missed=10; last_10_early_delay=10; last_10_early_abs=0;
incr_stabil = 10;

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
WORKING_MEMORY = 11;

state=FIRST_TRIAL;

% Reward-related
left=1; right=-1;
current_cond=randi([1,2],1,1);
current_cond = (current_cond-1.5)*2;
cond_count=0;

%% Ask about training info
weight = input(['Mouse ' num2str(mouse_id) ' weight \n:']);
pre_note = input("Anything special before the experiment? \n:");


%% Start the task
n=0;
disp(['starting the task, time: ' datestr(now,'dd-mm-yyyy HH:MM:SS.FFF')]);
% Start the task
training_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
train_t_max = 80; too_long = 0;
writeDigitalPin(mypi,pin_ca_imaging,1);
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


% give_freebies(4,3,mypi);

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
while ( n < n_trials ) && (too_many_tr_missed==0) % && (tone_n <= trials_total) 

%     %% Detect lick
%     % Shift values in the buffer by 1 position adding the previous reading
%     % as the last, then compare the sum of it to the new value
%     
% 
%     % Left
%     for i=2:sens_buffer_len
%         sens_buffer_left(i-1) = sens_buffer_left(i);
%     end
% 
%     sens_buffer_left(sens_buffer_len) = sens_before_left;
%     sens_now_left = readDigitalPin(mypi,pin_sens_left);
%     if (sum(sens_buffer_left) == 0) && (sens_now_left == 1)
%         lick_detected_left = 1;
%         left_lick_time = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
%                 'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
%         left_lick_times = [left_lick_times milliseconds(training_start-left_lick_time)];
%     else
%         lick_detected_left = 0;
%     end
%     sens_before_left = sens_now_left;
%     
%     % Right
%     for i=2:sens_buffer_len
%         sens_buffer_right(i-1) = sens_buffer_right(i);
%     end
%     sens_buffer_right(sens_buffer_len) = sens_before_right;
%     sens_now_right = readDigitalPin(mypi,pin_sens_right);
%     if (sum(sens_buffer_right) == 0) && (sens_now_right == 1)
%         lick_detected_right = 1;
%         right_lick_time = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
%                 'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
%         right_lick_times = [right_lick_times milliseconds(training_start-right_lick_time)];
%     else
%         lick_detected_right = 0;
%     end
%     sens_before_right = sens_now_right;

    scr_detect_lick;
   
    %% 1st trial to begin
    if state == FIRST_TRIAL
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

    % Set the laser open/close status depending on the trial type
        


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

            if current_cond == left
                PsychPortAudio('Start', pa_high, 1, 0, 0);
                tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
                left_tone_times(tone_n) = milliseconds(training_start-tone_start);
                tone_times(tone_n) = milliseconds(training_start-tone_start);
            else 
                PsychPortAudio('Start', pa_low, 1, 0, 0);
                tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
                right_tone_times(tone_n) = milliseconds(training_start-tone_start);
                tone_times(tone_n) = milliseconds(training_start-tone_start);
            end 
        
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
            lick_1st = 1;
            

            
        
        % Blast the laser for Arch
        writeDigitalPin(mypi,pin_laser,1);
        



            % Play the tone according to the condition
            current_cond=seq_side(tone_n);



            if current_cond == left
                PsychPortAudio('Start', pa_high, 1, 0, 0);
                tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
                left_tone_times(tone_n) = milliseconds(training_start-tone_start);
                tone_times(tone_n) = milliseconds(training_start-tone_start);
            else 
                PsychPortAudio('Start', pa_low, 1, 0, 0);
                tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
                right_tone_times(tone_n) = milliseconds(training_start-tone_start);
                tone_times(tone_n) = milliseconds(training_start-tone_start);
            end 
        pause(0.01);
        writeDigitalPin(mypi,pin_laser,0);
        
        end
    end
    
    %% Tone waiting out
    if state == TONE
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % After tone's time is over, stop it and transition to waiting for
        % licks
        if milliseconds(time_now - tone_start) >= 1150
%             if lick_1st == 1
%                 anticip = [anticip 0];
%             end
            early_lick_trials_abs(tone_n) = 0;
%             if early_lick_trials_abs(10) < 3
%                 last_10_early_abs = sum( early_lick_trials_abs(tone_n-9:tone_n) );
%                % disp(["early abs lick rate: " num2str( last_10_early_abs )]);
%                 plot(tone_n, last_10_early_abs, 'r*');
%                 xlim([0 tone_n+1]);
%             end
            if current_cond == left
                PsychPortAudio('Stop', pa_high);
            else
                PsychPortAudio('Stop', pa_low);
            end
            state = WORKING_MEMORY;
            working_memory_starts = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        
        elseif (lick_detected_left) || (lick_detected_right)
%             if lick_1st == 1
%                 anticip = [anticip 1];
%                 lick_1st = 0;
%             end
            early_lick_trials_abs(tone_n) = 1;
            early_lick = [ early_lick milliseconds(time_now - tone_start)];
%             if early_lick_trials_abs(10) < 3
%                 last_10_early_abs = sum( early_lick_trials_abs(tone_n-9:tone_n) );
%                % disp(["early lick at: " num2str( milliseconds(time_now - tone_start) )]);
%                 plot(tone_n, last_10_early_abs,'r*');
%                 xlim([0 tone_n+1]);
%             end
%             if punish_antic == 1
% %                 PsychPortAudio('Start', pa_punish, 1, 0, 0);
% %                 pause(0.05);
% %                 PsychPortAudio('Stop', pa_punish);
%                 disp(['anticipatory lick during the sound']);
%                 early_lick = [ early_lick milliseconds(time_now - tone_start)];
%                 early_lick_trials_delay(tone_n) = 1;
%                 if early_lick_trials_delay(10) < 3
%                     last_10_early_delay = sum( early_lick_trials_delay(tone_n-9:tone_n) );
%                    % disp(["early delay lick rate: " num2str( last_10_early_delay )]);
%                     plot(tone_n, last_10_early_delay, 'k*');
%                     xlim([0 tone_n+1]);
%                 end
%                 state = WAIT_PUNISHMENT_TIME_OUT;
%                 punish_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
%                     'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
%             end
        end
        
    end
    
    %% Period of time when a mouse needs to use working memory
    if state==WORKING_MEMORY
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % After waiting time is over, stop it and transition to response
        if milliseconds(time_now - working_memory_starts) >= 0
            early_lick_trials_delay(tone_n) = 0;
            if early_lick_trials_delay(10) < 3
                last_10_early_delay = sum( early_lick_trials_delay(tone_n-9:tone_n) );
               % disp(["early delay lick rate: " num2str( last_10_early_delay )]);
                plot(tone_n, last_10_early_delay, 'k*');
                xlim([0 tone_n+1]);
            end
            % Put servo to the mouth
%             writePosition(serv,servo_near);
            % Start playing go cue
            
            PsychPortAudio('Start', pa_go, 1, 0, 0);
            response_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            state = RESPONSE;
            
        elseif (lick_detected_left) || (lick_detected_right)
%             PsychPortAudio('Start', pa_punish, 1, 0, 0);
%             pause(0.05);
%             PsychPortAudio('Stop', pa_punish);
            disp('lick during working memory delay');
            early_lick = [ early_lick milliseconds(time_now - tone_start)];
            early_lick_trials_delay(tone_n) = 1;
            if early_lick_trials_delay(10) < 3
                last_10_early_delay = sum( early_lick_trials_delay(tone_n-9:tone_n) );
              %  disp(["early delay lick rate: " num2str( last_10_early_delay )]);
                plot(tone_n, last_10_early_delay, 'k*');
                xlim([0 tone_n+1]);
            end
            state = WAIT_PUNISHMENT_TIME_OUT;
            punish_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
        
    end
    
    %% Punishment time out for not waiting
    if state == WAIT_PUNISHMENT_TIME_OUT
        if lick_detected_left || lick_detected_right
%             PsychPortAudio('Start', pa_punish, 1, 0, 0);
%             pause(0.05);
%             PsychPortAudio('Stop', pa_punish);
%             writePosition(serv,servo_away);
            state = PRE_TONE_DELAY;
            pre_tone_delay_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
        
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % After punishment's time is over, stop it and transition to waiting for
        % licks
        if milliseconds(time_now-punish_start) >= (wait_punish_time_out_dur+randi(200))
%             writePosition(serv,servo_away);
            state = PRE_TONE_DELAY;
            pre_tone_delay_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
    end
    
    %% Waiting for licks
    if state == RESPONSE
        
        if (current_cond==left) && length(left_trial_correct)>=max_wrong && (sum(left_trial_correct(end-max_wrong+1:end)) == 0)
            disp('undeserved reward');
            free(tone_n) = 1;
            state=REWARD;
            left_trial_correct = [left_trial_correct .5];
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
            right_trial_correct = [right_trial_correct .5];
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
                freebie_n = freebie_n+1;
                disp(['~~~ FREEBIE #' num2str(freebie_n) ' ~~~']);
                free(tone_n) = 2;
                state=REWARD;
                
               missed_trials(tone_n) = 0;
                if tone_n >10
                    last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                    
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
            choice_made(tone_n) = 1;
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
%         if reward_alt == 1
%             if ((current_cond==left) && (lick_detected_left==1)) || (current_cond==right) && (lick_detected_right==1)
%                 state = LASER_PREP;
%                 disp('hop');
%                 PsychPortAudio('Stop', pa_go);
%                 pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
%                     'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
%             end
%         end
    
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                  'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % Move to the pre-tone delay after the timeout is over
        if milliseconds(time_now-choice_punish_timeout_start)>=choice_punish_time_out_dur
%             writePosition(serv,servo_away);
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
           % if mouse_id == 42
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
         %   end
            pause(.1);
            
            writeDigitalPin(mypi,pin_valv_left,1);
            
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
            
            disp(['left lick reward; trial #' num2str(n) ]); 
        else
        %if mouse_id == 42  
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
        %end
            pause(.1);
            
            writeDigitalPin(mypi,pin_valv_right,1);
            
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
            
            disp(['right lick reward; trial #' num2str(n) ]);  
        end
        if n>=imaged_trials
            writeDigitalPin(mypi,pin_ca_imaging,0);
        end
        % pause(2);
        PsychPortAudio('Stop', pa_go);
%         writePosition(serv,servo_away);
        state = LASER_PREP;
        pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % increment the delay if the last 10 trials had 10% or less wait
        % and 10% or less missed trials
        incr_stabil=incr_stabil+1;
        if (last_10_missed<=2) & (last_10_early_delay<=2)
            
            if incr_stabil>=5
                incr_stabil=0;
                
            end
        end
    end
    
    

    
    
end

% % Play end tone & close the audio device:
sound_end;


post_note = input(["Anything special after the experiment? \n:"]);
if ~exist(['os_data_figs/os' num2str(mouse_id) ], 'dir')
       mkdir()
    end
discr=1;

save(['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_B3.mat'], ...
    'missed_trials', 'seq_laser', 'seq_side', 'tone_times', 'choice_made', ...
    'left_trial_correct', 'right_trial_correct', 'training_start',...
    'left_lick_times', 'right_lick_times', 'free',...
    'left_tone_times','right_tone_times','trial_order', 'weight', 'discr', ...
    'pre_note', 'post_note', 'n', 'reward_alt');

if current_wait == 2000
    punish_antic=1;
else
    punish_antic=0;
end

current_stage = 3;

% Truncate
missed_trials = missed_trials(1:tone_n)';
seq_laser = seq_laser(1:tone_n)';
seq_side = seq_side(1:tone_n)';
tone_times = tone_times(1:tone_n)';
choice = choice_made(1:tone_n)';
free = free(1:tone_n)';

save(['reference_oscc' num2str(mouse_id) '.mat'], 'seq_laser','seq_side', 'tone_times', 'choice_made', ...
    'missed_trials', 'free', ...
    'left_trial_correct','right_trial_correct', 'punish_antic', ...
    'current_wait', 'reward_alt', 'current_stage');


saveas(gcf, ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_B3.fig']);
saveas(gcf, ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_B3.jpg']);


% Save csv 
results_table = table(missed_trials, seq_laser, seq_side, tone_times, choice, free,...
        'VariableNames', {'missed', 'laser', 'side', 'tone_ts', 'choice', 'free'});
writetable(results_table,[ 'os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_discr_laser_'  datestr(now,'dd-mm-yyyy_HH-MM') '.csv']);

writematrix(right_lick_times', ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_t_licks_R_'  datestr(now,'dd-mm-yyyy_HH-MM')  '.csv']);
writematrix(left_lick_times', ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_t_licks_L_'  datestr(now,'dd-mm-yyyy_HH-MM')  '.csv']);


wait_ratio = sum(early_lick_trials_delay(1:tone_n))/(tone_n-sum(missed_trials))
correct_left = sum(left_trial_correct)/length(left_trial_correct)
correct_right = sum(right_trial_correct)/length(right_trial_correct)
anticip_ratio = sum(anticip)/length(anticip)
try 
    d=sort(early_lick);
    median_early_lick = d( floor ( (length(early_lick_trials_delay)-sum(missed_trials))/2 ) )
end
training_end = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
training_duration = training_end - training_start;
disp(['training duration: ' datestr(training_duration,'HH:MM:SS.FFF')]);
% writePosition(serv,servo_near);
disp(['Mouse did ' num2str(n) ' trials']);