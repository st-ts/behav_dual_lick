% For the dual lick working memory experiment
% 3rd stage of training
% After licking any port, go cue sounds and water is provided

% In case there is an erroneaus restart, save all the variables
warning('off', 'raspi:utils:SaveNotSupported')
save(['D:\dual_lick\backup\' datestr(now,'yyyy-mm-dd-_HH_MM_SS') '.mat']);
%% Clear and close all
close all; clear all; format compact;

%% Important parameters to set up
mouse_id = input('Mouse id\n:'); 

% Help the poor mousie
freebie = 1; freebie_n = 0; freebie_max = 4; missed_till_freebie = 6; freebie_tone_prev = 0; freebie_pause = 3;
max_wrong = 4; 
max_tr_missed = 10;


% else
%     port_lr_move = 0;
% end
n_trials=350; % 

if mouse_id == 44
    n_trials = 6;
    missed_till_freebie = 2;
    max_tr_missed = 3;
elseif mouse_id == 77
    reward_alt = 1;
end

%% hmm
training_type = 'A3';


pre_tone_delay_dur=500; % in milliseconds
response_dur = 2500;
reward_dur_ms = 9;
% Load the calibrated valves data
% load('reference_oscc4.mat');
% load('valves_calibrated.mat');

% Load & set the training stage data
load(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/reference_oscc' num2str(mouse_id) '.mat']);
wait_increment = 0;

left_trial_correct_nonan = left_trial_correct (~isnan(left_trial_correct));
right_trial_correct_nonan = right_trial_correct (~isnan(right_trial_correct));
prev_correct_left = sum(left_trial_correct, 'omitnan')/length(left_trial_correct_nonan);
prev_correct_right = sum(right_trial_correct, 'omitnan')/length(right_trial_correct_nonan);
discrim=dprime(prev_correct_left,1-prev_correct_right);



temp_rew_alt = 0;
if reward_alt == 0
    disp("random order as prev day");
elseif discrim>1 & prev_correct_left>.55 && prev_correct_right > .55
    reward_alt = 0;
    disp(" new random order");
else
    reward_alt = 1;
    disp("Rewards alternating");
end

current_wait=0;

choice_punish_time_out_dur = 12000;

max_tone_n = 2000;

%% Initializing sounds
sound_init;


%% Time logging related variables
left_lick_times = zeros(1,max_tone_n*7); 
right_lick_times = zeros(1,max_tone_n*7); 
port_move_back = zeros(1,max_tone_n);
port_move_left = zeros(1,max_tone_n);
lick_n_L = 0;
lick_n_R= 0;
left_tone_times = zeros(1,max_tone_n);
right_tone_times = zeros(1,max_tone_n);
current_waits = zeros(1,n_trials);
trial_order = ones(1,max_tone_n)*3;


switch_max = 5;
alterns = [1 1 1 1 2 2 2 2 3 3 3 4 4 5];
switch_cond = randsample(alterns, 1);


%% Set up raspberry pi
rasp_init;

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

%% Stats tracking variables
% total_trials = [70
%];

tone_n=0;
early_lick_trials_abs = ones(1,max_tone_n)*3; % 1 if early lick, 0 otherwise
early_lick_trials_delay = ones(1,max_tone_n)*3;
missed_trials = zeros(1, max_tone_n); % 1 if missed, 0 otherwise
choice_made = zeros(1,max_tone_n);
freebies_undeserved = zeros(1,max_tone_n); % 1 for freebie for missed trial, 2 for underesrved choice 
% left_trial_correct = []; % 1 if correct, 0 if right is chosen instead of left
% right_trial_correct = []; % otherwise 
left_trial_correct = NaN(1,max_tone_n); % 1 if correct, 0 if right is chosen instead of left
right_trial_correct =  NaN(1,max_tone_n); % otherwise 
right_trial_correct_nonan = [];
left_trial_correct_nonan = [];
too_many_trials_missed=0;
anticip = []; % Monitor anticipatory licking
licked_already = 0;




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
RESPONSE_CUE = 6;
CHOICE_PUNISHMENT_TIME_OUT = 8;
FIRST_TRIAL = 9;
REWARD_INTAKE = 10;
state=FIRST_TRIAL;

% Reward-related
left=1; right=-1;
current_cond=randi([1,2],1,1);
current_cond = (current_cond-1.5)*2;
cond_count=0;

%% Ask about training info
weight = input(['Mouse ' num2str(mouse_id) ' weight \n:']);
pre_note = input("Anything special before the experiment? \n:", "s");


%% Start the task
n=0;
disp(['starting the task, time: ' datestr(now,'dd-mm-yyyy HH:MM:SS.FFF')]);
% Start the task
training_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
train_t_max = 80; too_long = 0;
% writeDigitalPin(mypi,pin_ca_imaging,1);
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

if mouse_id ~= 44
    give_freebies(4,3,mypi);
end

% writePosition(serv,servo_away);
while ( n < n_trials ) && (too_many_trials_missed==0) && (tone_n<=max_tone_n) && (too_long==0)
%for i=1:10000
    %% Detect lick
    % Shift values in the buffer by 1 position adding the previous reading
    % as the last, then compare the sum of it to the new value
%     % Left
%     for i=2:sens_buffer_len
%         sens_buffer_left(i-1) = sens_buffer_left(i);
%     end
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
        % When delay is over, transition to sound and start the tone
        if milliseconds(time_now-pre_tone_delay_start)>=pre_tone_delay_dur

             % Make versions of correct trials with no nans
            left_trial_correct_nonan = left_trial_correct (~isnan(left_trial_correct));
            right_trial_correct_nonan = right_trial_correct (~isnan(right_trial_correct));
            
            



            state=TONE;
            tone_n=tone_n+1;

            if  reward_alt == 1
                if cond_count >= switch_cond
                    switch_cond = randsample(alterns, 1);
                    current_cond=-current_cond;
                    cond_count=0;
                    
                end 
            else
                    %current_cond=randsample([left right],1);
            current_cond=randi([1,2],1,1);
            current_cond = (current_cond-1.5)*2;
                    trial_order(tone_n) = current_cond; 
            end
            % Play the tone according to the condition
            if current_cond == left
%                 PsychPortAudio('Start', pa_high, 1, 0, 0);
                send_rasp_pulse(mypi, pin_tone_left,10);
                tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
                left_tone_times(tone_n) = milliseconds(training_start-tone_start);
            else 
%                 PsychPortAudio('Start', pa_low, 1, 0, 0);
                send_rasp_pulse(mypi, pin_tone_right,10);
                tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
                right_tone_times(tone_n) = milliseconds(training_start-tone_start);
            end 
        
        end
        
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

            if n > 200
                freebie = 0;
            end

            left_trial_correct_nonan = left_trial_correct (~isnan(left_trial_correct));
            right_trial_correct_nonan = right_trial_correct (~isnan(right_trial_correct));
            % Move the ports to the left / right if there are X wrong side
            %choices in a row
%             if port_lr_move && length(left_trial_correct_nonan) >= side_wrong_to_step && ...
%                     sum(left_trial_correct_nonan(end - side_wrong_to_step + 1:end))== 0 ...
%                     && stepped_left > too_right && ~missed_trials(tone_n)
% 
%                 if tone_n < 50
%                     move(stepper_lr, - stepper_lr_steps*3); release(stepper_lr);
%                     stepped_left = stepped_left - stepper_lr_steps*3;
%                 elseif tone_n < 100
%                     move(stepper_lr, - stepper_lr_steps); release(stepper_lr);                
%                     stepped_left = stepped_left - stepper_lr_steps;
%                 else
%                     move(stepper_lr, - stepper_lr_steps*0.5); release(stepper_lr);                
%                     stepped_left = stepped_left - stepper_lr_steps*0.5;
%                 end
% 
%                 disp(['left port closer: ' num2str(stepped_left)]);
%                 port_move_left(tone_n+1) = - 1;
%             end
% 
%             % Same for right
%             if port_lr_move && length(right_trial_correct_nonan) >= side_wrong_to_step && ...
%                     sum(right_trial_correct_nonan(end - side_wrong_to_step + 1:end)) == 0 ...
%                     && stepped_left < too_left && ~missed_trials(tone_n)
% 
%                 if tone_n < 50
%                     move(stepper_lr, stepper_lr_steps*3); release(stepper_lr);
%                     stepped_left = stepped_left + stepper_lr_steps*3;
%                 elseif tone_n < 100
%                     move(stepper_lr, stepper_lr_steps); release(stepper_lr);                
%                     stepped_left = stepped_left + stepper_lr_steps;
%                 elseif tone_n < 200
%                     move(stepper_lr, stepper_lr_steps*0.5); release(stepper_lr);                
%                     stepped_left = stepped_left + stepper_lr_steps*0.5;
%                 end
% 
%                 disp(['right port closer: ' num2str(stepped_left)]);
%                 port_move_left(tone_n+1) = 1;
%             end



            % If the discr is bad on random, switch to alternating
            % temporarily
            if  reward_alt == 0 && length(left_trial_correct_nonan) > 10 && length(right_trial_correct_nonan) > 10
                if sum(left_trial_correct_nonan(end-9:end)) < 2 || sum(right_trial_correct_nonan(end-9:end)) < 2
                    temp_rew_alt = 1; disp('temp alt');
                end
            end
            % Cancel temp_rew_alt once behavior improves
            if temp_rew_alt && sum(left_trial_correct(end-9:end)) > 4 && sum(right_trial_correct(end-9:end)) > 4
                % && length(left_trial_correct) > 10 && length(right_trial_correct) > 10
                disp('no more temp alt');
                temp_rew_alt = 0;
            end

            %% Do all the plotting in here
            if tone_n >11
                last_10_missed = sum( missed_trials(tone_n-10:tone_n-1) );
                plot(tone_n-1, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end





            %% Transition to the tone
            state=TONE;
            licked_already = 0;
            tone_n=tone_n+1;
            % current_cond=randsample([left right],1);
            if  reward_alt || temp_rew_alt
                if cond_count >= switch_cond

                    switch_cond = randsample(alterns, 1);
                    current_cond=-current_cond;
                    
                    cond_count=0;
                end 
            else
                    current_cond=randi([1,2],1,1);
        current_cond = (current_cond-1.5)*2;
                    trial_order(tone_n) = current_cond;  
            end
            if current_cond == left
                send_rasp_pulse(mypi, pin_tone_left,10);
%                 PsychPortAudio('Start', pa_high, 1, 0, 0);
                tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
                left_tone_times(tone_n) = milliseconds(training_start-tone_start);
            else 
                send_rasp_pulse(mypi, pin_tone_right,10);
%                 PsychPortAudio('Start', pa_low, 1, 0, 0);
                tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
                right_tone_times(tone_n) = milliseconds(training_start-tone_start);
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
%             if licked_already == 0
%                 anticip = [anticip 0];
%             end
%             early_lick_trials_abs(tone_n) = 0;
%             if early_lick_trials_abs(10) < 3
%                 last_10_early_abs = sum( early_lick_trials_abs(tone_n-9:tone_n) );
%                % disp(["early abs lick rate: " num2str( last_10_early_abs )]);
%                 plot(tone_n, last_10_early_abs, 'r*');
%                 xlim([0 tone_n+1]);
%             end
%             if current_cond == left
%                 PsychPortAudio('Stop', pa_high);
%             else
%                 PsychPortAudio('Stop', pa_low);
%             end
            state = RESPONSE;
            response_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        
        end
        
    end
    
    
    
    
    %% Waiting for licks
    if state == RESPONSE   
        % Give reward undeservingly if the mouse made too many
        % discrimination errors
        if (current_cond==left) && length(left_trial_correct_nonan ) >= max_wrong ...
                && (sum(left_trial_correct_nonan(end-max_wrong+1:end),'omitnan') == 0)
            disp('undeserved reward');
            freebies_undeserved(tone_n) = 2;
            state=REWARD;
            left_trial_correct(tone_n) = 0.001;
            choice_made(tone_n)=0;
            if length(left_trial_correct_nonan) >=10
                last_10_left_corr = sum( left_trial_correct_nonan(end-9:end) );
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


    if (current_cond==right) && length(right_trial_correct_nonan) > max_wrong && (sum(right_trial_correct_nonan(end-max_wrong + 1:end))  == 0)
            disp('undeserved reward');
            freebies_undeserved(tone_n) = 2;
            state=REWARD;
            right_trial_correct(tone_n) = 0.001;
            choice_made(tone_n)=0;
            if length(right_trial_correct_nonan) >=10
                last_10_right_corr = sum( right_trial_correct_nonan(end-9:end) );
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


        if tone_n >= missed_till_freebie+1
            if freebie && freebie_n < freebie_max && sum(missed_trials(tone_n-(missed_till_freebie):tone_n-1))==missed_till_freebie
%                 if tone_n ~= tone_n_missed % TROUBLESHOOTING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%                     disp(['missed a lot, tone#' num2str(tone_n)]);
%                     disp(missed_trials(tone_n-(missed_till_freebie):tone_n-1));
%                     disp(sum(missed_trials(tone_n-(missed_till_freebie):tone_n-1)));
%                     disp(tone_n);
%                     
%                     tone_n_missed = tone_n;
%                 end
                if tone_n - freebie_tone_prev > freebie_pause
                    state=REWARD;
                    freebie_n = freebie_n+1;
                    missed_trials(tone_n) = 0;
                    disp(['~~~ FREEBIE #' num2str(freebie_n) ' ~~~']);
                    freebies_undeserved(tone_n) = 1;
                    freebie_tone_prev = tone_n;
                end
                
            end
        end




        
        if (current_cond==left) && (lick_detected_left==1)
            left_trial_correct(tone_n) = 1;
            if length(left_trial_correct_nonan) >=10
                last_10_left_corr = sum( left_trial_correct_nonan(end-9:end) );
                plot(tone_n, last_10_left_corr-.1,'g*');
                xlim([0 tone_n+1]);
            end
            state=REWARD;
           % missed_trials = [missed_trials 0];
%             if tone_n >10
%                 last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
%                 plot(tone_n, last_10_missed+.1,'ro');
%                 xlim([0 tone_n+1]);
%             end

        elseif (current_cond==left) && (lick_detected_right==1)
            left_trial_correct(tone_n) = 0;
            if length(left_trial_correct_nonan) >=10
                last_10_left_corr = sum( left_trial_correct_nonan(end-9:end) );
                plot(tone_n, last_10_left_corr-.1,'g*');
                xlim([0 tone_n+1]);
            end
          %  missed_trials = [missed_trials 0];
%             if tone_n >10
%                 last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
%                 plot(tone_n, last_10_missed+.1,'ro');
%                 xlim([0 tone_n+1]);
%             end
            disp("licked right instead of left");
            
            state = CHOICE_PUNISHMENT_TIME_OUT;
            choice_punish_timeout_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        elseif (current_cond==right) && (lick_detected_right==1) 
            right_trial_correct(tone_n) = 1;
            if length(right_trial_correct_nonan) >=10
                last_10_right_corr = sum( right_trial_correct_nonan(end-9:end) );
                plot(tone_n, last_10_right_corr-.1,'b*');
                xlim([0 tone_n+1]);
            end
            state=REWARD;
          %  missed_trials = [missed_trials 0];
%             if tone_n >10
%                 last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
%                 plot(tone_n, last_10_missed+.1,'ro');
%                 xlim([0 tone_n+1]);
%             end
        elseif (current_cond==right) && (lick_detected_left==1)
            right_trial_correct(tone_n) = 0;
            if length(right_trial_correct_nonan) >=10
                last_10_right_corr = sum( right_trial_correct_nonan(end-9:end) );
                plot(tone_n, last_10_right_corr-.1,'b*');
                xlim([0 tone_n+1]);
            end
           % missed_trials = [missed_trials 0];
%             if tone_n >10
%                 last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
%                 plot(tone_n, last_10_missed+.1,'ro');
%                 xlim([0 tone_n+1]);
%             end
            disp("licked left instead of right");
            
            state = CHOICE_PUNISHMENT_TIME_OUT;
            choice_punish_timeout_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
              'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        if milliseconds(time_now-response_start)>=response_dur
            missed_trials(tone_n) = 1;
%             if tone_n >10
%                 last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
%                 plot(tone_n, last_10_missed+.1,'ro');
%                 xlim([0 tone_n+1]);
%             end
            disp("missed trial");

            % Check if the mouse has been missing too many trials and stop
            % the run if it did
            if tone_n >= max_tr_missed + 2
                if sum(missed_trials(tone_n-max_tr_missed+1:tone_n)) >= max_tr_missed
                    too_many_trials_missed=1;
                end
            end

%             writePosition(serv,servo_away);
            state = PRE_TONE_DELAY;
%             PsychPortAudio('Stop', pa_go);
            pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
        

    end
    
    %% Choice punishment
    if state== CHOICE_PUNISHMENT_TIME_OUT
        if reward_alt == 1
            if ((current_cond==left) && (lick_detected_left==1)) || (current_cond==right) && (lick_detected_right==1)
                state = PRE_TONE_DELAY;
                disp('hop');
%                 PsychPortAudio('Stop', pa_go);
                pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                    'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            end
        end
    
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                  'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % Move to the pre-tone delay after the timeout is over
        if milliseconds(time_now-choice_punish_timeout_start)>=choice_punish_time_out_dur
%             writePosition(serv,servo_away);
            state = PRE_TONE_DELAY;
%             PsychPortAudio('Stop', pa_go);
            pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
        

    end
    
    %% Reward
    if state == REWARD
        if current_wait>=1500
            wait_increment=0;
            current_wait=1500;
        end
        
        n=n+1;
        current_waits(n) = current_wait;
        cond_count=cond_count+1;
        if current_cond == left
           % if mouse_id == 42
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
         %   end
            pause(.2);
            
            writeDigitalPin(mypi,pin_valv_left,1);
            
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
            
            disp(['left lick detected, current wait: ' num2str(current_wait) 'ms; trial #' num2str(n) ]); 
        else
        %if mouse_id == 42  
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
        %end
            pause(.2);
            
            writeDigitalPin(mypi,pin_valv_right,1);
            
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
            
            disp(['right lick detected, current wait: ' num2str(current_wait) 'ms; trial #' num2str(n) ]);  
        end

        pause(2);
%         PsychPortAudio('Stop', pa_go);
%         writePosition(serv,servo_away);
        state = PRE_TONE_DELAY;
        pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % increment the delay if the last 10 trials had 10% or less wait
        % and 10% or less missed trials
        incr_stabil=incr_stabil+1;
        if (last_10_missed<=2) && (last_10_early_delay<=2)
            
            if incr_stabil>=5
                incr_stabil=0;
                current_wait=current_wait+wait_increment;
            end
        end
    end
    
    

    
    
end

% % Play end tone & close the audio device:
sound_end;

weight_after = input(['Mouse ' num2str(mouse_id) ' weight after \n:']);



training_end = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
training_duration = training_end - training_start;

post_note = input(["Anything special after the experiment? \n:"], "s");
discr=1;


% truncate
left_lick_times = left_lick_times(1:lick_n_L);
right_lick_times = right_lick_times(1:lick_n_R);


% Save
reward_alt=1;

save_behav_all;

% 
% % Create the folder for the results if it deosn't exist
% if ~exist(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) ], 'dir')
%        mkdir(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) ]);
% %     end
% discr=1;
% %save(['dual_lick_A3_oscc0' num2str(mouse_id) '_' datestr(now,'dd-mm-yyyy_HH-MM') '.mat'], ...
% save(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_A3.mat'], ...
%     'missed_trials', 'early_lick', 'early_lick_trials_delay', 'early_lick_trials_abs', 'current_wait', ...
%     'left_trial_correct','right_trial_correct', 'training_start',...
%     'current_waits','left_lick_times','right_lick_times', ...
%     'left_tone_times','right_tone_times','trial_order', 'weight', 'discr', ...
%     'pre_note', 'post_note', 'training_type', 'n', 'reward_alt', 'anticip', 'weight_after');
% 
% 
% current_stage = 3;
% save(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/reference_oscc' num2str(mouse_id) '.mat'], ...
%     'missed_trials', 'early_lick', 'early_lick', 'early_lick_trials_abs', 'current_wait', ...
%     'left_trial_correct','right_trial_correct', ...
%     'left_trial_correct_nonan','right_trial_correct_nonan', ...
%     'wait_increment', 'current_wait', 'reward_alt', 'current_stage',  'port_move_left');
% 
% 
% saveas(gcf, ['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_A3.fig']);
% saveas(gcf, ['D:/dual_lick/os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_A3.jpg']);
   % 'dual_lick_A3_oscc0' num2str(mouse_id) '_' datestr(now,'dd-mm-yyyy_HH-MM') '.fig']);
% saveas(gcf, ['dual_lick_A3_oscc0' num2str(mouse_id) '_' datestr(now,'dd-mm-yyyy_HH-MM') '.jpg']);

correct_left = sum(left_trial_correct_nonan, 'omitnan')/length(left_trial_correct_nonan)
correct_right = sum(right_trial_correct_nonan, 'omitnan')/length(right_trial_correct_nonan)

try 
    d=sort(early_lick);
    median_early_lick = d( floor ( (length(early_lick_trials_delay)-sum(missed_trials))/2 ) )
end

disp(['training duration: ' datestr(training_duration,'HH:MM:SS.FFF')]);
% writePosition(serv,servo_near);
disp(['Mouse did ' num2str(n) ' trials']);


%% Data for saving the file
training_stage = 'A3'; 