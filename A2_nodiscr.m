% For the dual lick working memory experiment
% 2nd stage of training
% After licking any port, go cue sounds and water is provided
%% Clear and close all

% % Close the audio device:
% PsychPortAudio('Stop', pamaster);
% PsychPortAudio('Close', pa_go);
% PsychPortAudio('Close', pa_low);
% PsychPortAudio('Close', pa_high);

% PsychPortAudio('Close', pa_end);
% PsychPortAudio('Close', pamaster);
% % toc

close all; clear variables; format compact;

%% Important parameters to set up
mouse_id = input('Mouse id\n:'); 
freebie = 1; freebie_max = 12; freebie_n = 1; max_missed_tr_fr = 5;
n_trials =350; 
max_tries = ceil(n_trials*2); 
imaged_trials = 100; 
pre_tone_delay_dur=500; % in milliseconds

response_dur = 2000;
resp_dur_decr = 1;

%     load('valves_calibrated.mat');
punish_antic = 0; 
%load(['reference_oscc' num2str(mouse_id) '.mat']); 
current_wait=0; 
wait_increment=0; 
tone_duration = 1150; 
max_missed_tr = 16;
% left_trial_correct = left_trial_correct(1:find(left_trial_correct==9,1)-1);
% right_trial_correct = right_trial_correct(1:find(right_trial_correct==9,1)-1);
% prev_correct_left = sum(left_trial_correct)/length(left_trial_correct);
% prev_correct_right = sum(right_trial_correct)/length(right_trial_correct);
% if (prev_correct_left > 0.75) & (prev_correct_right > 0.75) 
%     mouse3rew = 0;
%     disp("random order");
% else
mouse3rew = 1;
disp("3 rew alternating");
% end

wait_punish_time_out_dur = 800;
choice_punish_time_out_dur = 4000;
max_tone_n = 2000;




%% Initializing sounds

sound_init;


%% Time logging related variables
left_lick_times = zeros(1,max_tone_n*7); 
right_lick_times = zeros(1,max_tone_n*7); 
lick_n_L = 0;
lick_n_R= 0;
left_tone_times = zeros(1,max_tone_n);
right_tone_times = zeros(1,max_tone_n);
current_waits = zeros(1,n_trials);
trial_order = ones(1,max_tone_n)*3;

%% Monitor anticipatory licking
anticip = 9*ones(1,2000);
tr = 0;
lick_1st = 1;

%% Set up raspberry pi
mypi = raspi('169.254.156.249', 'pi', 'raspberry');

% Asign and configure pins
load('reference_rasp.mat'); % file with all the pin numbers and values for servo open / close

configurePin(mypi,pin_sens_left,'DigitalInput');
configurePin(mypi,pin_sens_right,'DigitalInput');
configurePin(mypi,pin_valv_left,'DigitalOutput');
configurePin(mypi,pin_valv_right,'DigitalOutput');
configurePin(mypi,pin_ca_imaging,'DigitalOutput');
serv = servo(mypi, pin_servo_water);

%writePosition(serv,port_near);

%% Stepper
port_lr_move = 1;
ardu = arduino('COM5','Uno','Libraries','Adafruit\MotorShieldV2');
shield = addon(ardu,'Adafruit\MotorShieldV2');
addrs = scanI2CBus(ardu,0);

stepper_lr = stepper(shield,1,200);
stepper_lr.RPM = 200;
stepper_lr_steps = 100; % 
stepped_left = 0; too_left = 2400; too_right = - 2400; % find out empiricaylly
side_wrong_to_step = 4;


port_move_left = zeros(1,max_tone_n);


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
% total_trials = [];

tone_n=0;
early_lick_trials_abs = ones(1,max_tone_n)*3; % 1 if early lick, 0 otherwise
early_lick_trials_delay = ones(1,max_tone_n)*3;
missed_trials = 9*ones(1,2000); % 1 if missed, 0 otherwise
left_trial_correct = 9*ones(1,600); l_tr = 1; % 1 if correct, 0 if right is chosen instead of left
right_trial_correct =  9*ones(1,600); r_tr = 1; % otherwise 
choice_made = ones(1,max_tone_n)*3;
too_many_trials_missed=0;

%% Increment related variebles
early_lick =zeros(1,5000);
early_lick_n = 1;
last_10_missed=10; last_10_early_delay=10; last_10_early_abs=0;
incr_stabil = 10;

%% State related variables
TONE = 1;
RESPONSE = 2;
GO_CUE = 3;
REWARD = 4;
PRE_TONE_DELAY = 5;
RESPONSE_CUE = 6;
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
n=1;

disp(['starting the task, time: ' datestr(now,'dd-mm-yyyy HH:MM:SS.FFF')]);
% Start the task
training_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
writeDigitalPin(mypi,pin_ca_imaging,1);
pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
figure(1); hold on; ylim([-0.2 11])

plot(1, 1,'ro'); % missed
plot(1, 1,'b*'); % right correct
plot(1, 1,'g*'); % left correct
legend('missed', 'correct right', 'correct left', ...
        'AutoUpdate', 'off', "Location", "northwest");

% To make sure there's no sudden flash at the beginning
writeDigitalPin(mypi,pin_valv_right,0);
writeDigitalPin(mypi,pin_valv_right,0);
%     
writeDigitalPin(mypi,pin_valv_left,0);
writeDigitalPin(mypi,pin_valv_left,0);



give_freebies(4,3,mypi);


left_lick_time = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
right_lick_time = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

% writePosition(serv,servo_away);
while ( n < n_trials ) && (too_many_trials_missed==0) && (tone_n<=max_tries)

%for i=1:10000
    %% Detect lick
    % Shift values in the buffer by 1 position adding the previous reading
    % as the last, then compare the sum of it to the new value
    % Left
%     for i=2:sens_buffer_len
%         sens_buffer_left(i-1) = sens_buffer_left(i);
%     end
%     sens_buffer_left(sens_buffer_len) = sens_before_left;
%     sens_now_left = readDigitalPin(mypi,pin_sens_left);
%     if (sum(sens_buffer_left) == 0) && (sens_now_left == 1)
%         lick_detected_left = 1;
%         left_lick_time = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
%                 'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
%         lick_n_L = lick_n_L +1;
%         left_lick_times(lick_n_L) = milliseconds(training_start-left_lick_time);
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
%         lick_n_R = lick_n_R +1;
%         right_lick_times(lick_n_R) = milliseconds(training_start-right_lick_time);
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
            state=TONE;
            tone_n=tone_n+1;
            % current_cond=randsample([left right],1);
            if mouse3rew == 1
                if cond_count >= 3
                    current_cond=-current_cond;
                    cond_count=0;
                end 
            else
                    current_cond=randsample([left right],1);
                    trial_order(tone_n) = current_cond; 
            end



            % Play the tone according to the condition
            if current_cond == left
                PsychPortAudio('Start', pa_high, 1, 0, 0);
                tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
                left_tone_times(tone_n) = milliseconds(training_start-tone_start);
            else 
                PsychPortAudio('Start', pa_low, 1, 0, 0);
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
        % When delay is over, transition to sound and start the tone
        if milliseconds(time_now-pre_tone_delay_start)>=pre_tone_delay_dur+randi(1000)
             % Move the ports to the left / right if there are X wrong side
            %choices in a row
            if port_lr_move && l_tr >= side_wrong_to_step + 1 && ...
                    sum(left_trial_correct(l_tr - side_wrong_to_step + 1:l_tr))== 0 ...
                    && stepped_left > too_right && ~missed_trials(tone_n)
                if tone_n < 40
                    move(stepper_lr, - stepper_lr_steps*2); release(stepper_lr);
                    stepped_left = stepped_left - stepper_lr_steps*2;
                elseif tone_n < 100
                    move(stepper_lr, - stepper_lr_steps); release(stepper_lr);                
                    stepped_left = stepped_left - stepper_lr_steps;
                else
                    move(stepper_lr, - stepper_lr_steps*0.5); release(stepper_lr);                
                    stepped_left = stepped_left - stepper_lr_steps*0.5;
                end
                disp(['left port closer: ' num2str(stepped_left)]);
                port_move_left(tone_n+1) = - 1;
            end

            % Same for right
            if port_lr_move && r_tr >= side_wrong_to_step + 1 && ...
                    sum(right_trial_correct(r_tr - side_wrong_to_step + 1:r_tr))== 0 ...
                    && stepped_left < too_left && ~missed_trials(tone_n)
                if tone_n < 40
                    move(stepper_lr, stepper_lr_steps*2); release(stepper_lr);
                    stepped_left = stepped_left + stepper_lr_steps*2;
                elseif tone_n < 100
                    move(stepper_lr, - stepper_lr_steps); release(stepper_lr);                
                    stepped_left = stepped_left + stepper_lr_steps;
                else
                    move(stepper_lr, - stepper_lr_steps*0.5); release(stepper_lr);                
                    stepped_left = stepped_left + stepper_lr_steps*0.5;
                end
                disp(['right port closer: ' num2str(stepped_left)]);
                port_move_left(tone_n+1) = 1;
            end

% 
%             if port_lr_move && length(right_trial_correct_nonan) >= side_wrong_to_step && ...
%                     sum(right_trial_correct_nonan(end - side_wrong_to_step + 1:end)) == 0 ...
%                     && stepped_left < too_left && ~missed_trials(tone_n)
%                 move(stepper_lr, stepper_lr_steps); release(stepper_lr);
%                 stepped_left = stepped_left + stepper_lr_steps;
%                 disp(['right port closer: ' num2str(stepped_left)]);
%                 port_move_left(tone_n+1) = 1;
%             end


            state=TONE;
            lick_1st = 1;
            tone_n=tone_n+1;
            % current_cond=randsample([left right],1);
            if  mouse3rew == 1
                if cond_count >= 3
                    current_cond=-current_cond;
                    cond_count=0;
                end 
            else
                    current_cond=randsample([left right],1);
                    trial_order(tone_n) = current_cond;  
            end
            if current_cond == left
                PsychPortAudio('Start', pa_high, 1, 0, 0);
                tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
                left_tone_times(tone_n) = milliseconds(training_start-tone_start);
            else 
                PsychPortAudio('Start', pa_low, 1, 0, 0);
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
        % licks6
        if milliseconds(time_now - tone_start) >= tone_duration
            if lick_1st == 1
                anticip(n) = 0;
            end
            early_lick_trials_abs(tone_n) = 0;
%             if early_lick_trials_abs(10) < 3
%                 last_10_early_abs = sum( early_lick_trials_abs(tone_n-9:tone_n) );
%                 disp(["early abs lick rate: " num2str( last_10_early_abs )]);
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
            if lick_1st == 1
                anticip(n) = 0;
                lick_1st = 0;
            end
            early_lick_trials_abs(tone_n) = 1;
            early_lick(early_lick_n) = milliseconds(time_now - tone_start);
            early_lick_n = early_lick_n+1;
%             if early_lick_trials_abs(10) < 3
%                 last_10_early_abs = sum( early_lick_trials_abs(tone_n-9:tone_n) );
%                 disp(["early lick at: " num2str( milliseconds(time_now - tone_start) )]);
%                 plot(tone_n, last_10_early_abs,'r*');
%                 xlim([0 tone_n+1]);
%             end
            if punish_antic == 1
                PsychPortAudio('Start', pa_punish, 1, 0, 0);
                pause(0.05);
                PsychPortAudio('Stop', pa_punish);
                disp('anticipatory lick during the sound');
                early_lick(early_lick_n) = milliseconds(time_now - tone_start);
                early_lick_n = early_lick_n+1;
                early_lick_trials_delay(tone_n) = 1;
%                 if early_lick_trials_delay(10) < 3
%                     last_10_early_delay = sum( early_lick_trials_delay(tone_n-9:tone_n) );
%                     disp(["early delay lick rate: " num2str( last_10_early_delay )]);
%                     plot(tone_n, last_10_early_delay, 'k*');
%                     xlim([0 tone_n+1]);
%                 end
                state = WAIT_PUNISHMENT_TIME_OUT;
                punish_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                    'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            end
        end
        
    end
    
    %% Period of time when a mouse needs to use working memory
    if state==WORKING_MEMORY
        resp_1st=1;
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % After waiting time is over, stop it and transition to response
        if milliseconds(time_now - working_memory_starts) >= current_wait
            early_lick_trials_delay(tone_n) = 0;
%             if early_lick_trials_delay(10) < 3
%                 last_10_early_delay = sum( early_lick_trials_delay(tone_n-9:tone_n) );
%                 disp(["early delay lick rate: " num2str( last_10_early_delay )]);
%                 plot(tone_n, last_10_early_delay, 'k*');
%                 xlim([0 tone_n+1]);
%             end
%             writePosition(serv,servo_near);
            pause(.1)
            % Start playing go cue
            PsychPortAudio('Start', pa_go, 1, 0, 0);
            response_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            state = RESPONSE;
            
        elseif (lick_detected_left) || (lick_detected_right)
            PsychPortAudio('Start', pa_punish, 1, 0, 0);
            pause(0.05);
            PsychPortAudio('Stop', pa_punish);
            disp('lick during working memory delay');
            early_lick(early_lick_n) = milliseconds(time_now - tone_start);
            early_lick_n = early_lick_n+1;
            early_lick_trials_delay(tone_n) = 1;
%             if early_lick_trials_delay(10) < 3
%                 last_10_early_delay = sum( early_lick_trials_delay(tone_n-9:tone_n) );
%                 disp(["early delay lick rate: " num2str( last_10_early_delay )]);
%                 plot(tone_n, last_10_early_delay, 'k*');
%                 xlim([0 tone_n+1]);
%             end
            state = WAIT_PUNISHMENT_TIME_OUT;
            punish_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
        
    end
    
    %% Punishment time out for not waiting
    if state == WAIT_PUNISHMENT_TIME_OUT
        if lick_detected_left || lick_detected_right
            PsychPortAudio('Start', pa_punish, 1, 0, 0);
            pause(0.05);
            PsychPortAudio('Stop', pa_punish);
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
        if tone_n >= max_missed_tr_fr+1 % 
            if sum(missed_trials(tone_n-max_missed_tr_fr:tone_n-1))==max_missed_tr_fr
                if freebie == 1
                    if freebie_n <= freebie_max
                        disp(["freebie #" num2str(freebie_n)] );
                        missed_trials(tone_n) = 0;
%                         tone_n=tone_n+1;
                        freebie_n=freebie_n+1;
                        state=REWARD;
                    end
                end
            end
        end


        if (current_cond==left) && (lick_detected_left==1) 
            
            if (resp_1st==1)
                left_trial_correct(l_tr) = 1; 
                if left_trial_correct(10) <2
                    last_10_left_corr = sum( left_trial_correct(l_tr-9:l_tr) );
                    plot(tone_n, last_10_left_corr-.1,'g*');
                    xlim([0 tone_n+1]);
                end
                l_tr = l_tr+1;
                resp_1st=0;
            end
            state=REWARD;
            missed_trials(tone_n) = 0;
            if n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
        elseif (current_cond==left) && (lick_detected_right==1) && (resp_1st==1)
            resp_1st = 0;
            left_trial_correct(l_tr) = 0; 
                if left_trial_correct(10) <2
                    last_10_left_corr = sum( left_trial_correct(l_tr-9:l_tr) );
                    plot(tone_n, last_10_left_corr-.1,'g*');
                    xlim([0 tone_n+1]);
                end
            l_tr = l_tr+1;
            missed_trials(tone_n) = 0;
            if n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
            disp("licked right instead of left 1st");
            
            %state = CHOICE_PUNISHMENT_TIME_OUT;
            %pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
             %   'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        elseif (current_cond==right) && (lick_detected_right==1) 
            if (resp_1st==1)
                right_trial_correct(r_tr) = 1; 
                if right_trial_correct(10) <2
                    last_10_right_corr = sum( right_trial_correct(r_tr-9:r_tr) );
                    plot(tone_n, last_10_right_corr-.1,'b*');
                    xlim([0 tone_n+1]);
                end
                r_tr = r_tr+1;
                resp_1st=0;
            end
            state=REWARD;
            missed_trials(tone_n) = 0;
            if n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
        elseif (current_cond==right) && (lick_detected_left==1) && (resp_1st==1)
            resp_1st=0;
            right_trial_correct(r_tr) = 0; 
                if right_trial_correct(10) <2
                    last_10_right_corr = sum( right_trial_correct(r_tr-9:r_tr) );
                    plot(tone_n, last_10_right_corr-.1,'b*');
                    xlim([0 tone_n+1]);
                end
                r_tr = r_tr+1;
            missed_trials(tone_n) = 0;
            if n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
            disp("licked left instead of right 1st");
            
           % state = CHOICE_PUNISHMENT_TIME_OUT;
           % pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
            %    'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
              'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        if milliseconds(time_now-response_start)>=response_dur
            missed_trials(tone_n) = 1;
            if n >10
                last_10_missed = sum( missed_trials(tone_n-9:tone_n) );
                plot(tone_n, last_10_missed+.1,'ro');
                xlim([0 tone_n+1]);
            end
            disp("missed trial");
            if n >= max_missed_tr+2 % 
                if sum(missed_trials(tone_n-max_missed_tr-1:tone_n))>=max_missed_tr-2
                    too_many_trials_missed=1;
                end
            end
%             writePosition(serv,servo_away);
            state = PRE_TONE_DELAY;
            PsychPortAudio('Stop', pa_go);
            pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
    end
    
    %% Choice punishment
    if state== CHOICE_PUNISHMENT_TIME_OUT
        pause(3);
%         writePosition(serv,servo_away);
        state = PRE_TONE_DELAY;
    end
    
    %% Reward
    if state == REWARD
        if current_wait>=2000
            wait_increment=0;
        end
        if response_dur > 250
            response_dur = response_dur-resp_dur_decr;
        end
        n=n+1;
        current_waits(n) = current_wait;
        cond_count=cond_count+1;
        
        if current_cond == left
            
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(0.1);
            
            writeDigitalPin(mypi,pin_valv_left,0);
            corr_latency = milliseconds(left_lick_time-response_start);
            disp(['left lick detected, trial #' num2str(n-1) ', latency: '  num2str(corr_latency) ' ms']); 
        else
            
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(0.1);
            
            writeDigitalPin(mypi,pin_valv_right,0);
            corr_latency = milliseconds(right_lick_time-response_start);
            disp(['right lick detected, trial #' num2str(n-1) ', latency: '  num2str(corr_latency) ' ms']); 
        end

        
        if n>=imaged_trials
            writeDigitalPin(mypi,pin_ca_imaging,0);
        end
        pause(1.1);
        PsychPortAudio('Stop', pa_go);
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
sound_end;


training_end = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
training_duration = training_end - training_start;
disp(['training duration: ' datestr(training_duration,'HH:MM:SS.FFF')]);


weight_after = input(['Mouse ' num2str(mouse_id) ' weight after \n:']);


post_note = input("Anything special after the experiment? \n:");

% Create the folder for the results if it deosn't exist
if ~exist(['os_data_figs/os' num2str(mouse_id) ], 'dir')
       mkdir(['os_data_figs/os' num2str(mouse_id) ]);
    end
discr=1;

% Truncate all behavioral data
missed_trials = missed_trials(1:tone_n);
early_lick = early_lick(1:tone_n);
early_lick_trials_delay = early_lick_trials_delay(1:tone_n);
early_lick_trials_abs = early_lick_trials_abs(1:tone_n);
left_trial_correct = left_trial_correct(1:l_tr-1);
right_trial_correct = right_trial_correct(1:r_tr-1);
left_lick_times = left_lick_times(1:lick_n_L);
right_lick_times = right_lick_times(1:lick_n_R);

% save(['dual_lick__A2_oscc0' num2str(mouse_id) '_' datestr(now,'dd-mm-yyyy_HH-MM') '.mat'], 
save(['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_A2.mat'], ...
    'missed_trials', 'early_lick', 'early_lick_trials_delay', 'early_lick_trials_abs', 'current_wait', ...
    'left_trial_correct','right_trial_correct', 'training_start',...
    'current_waits','left_lick_times','right_lick_times', 'punish_antic',...
    'left_tone_times','right_tone_times','trial_order', 'weight', ...
    'pre_note', 'post_note', 'n', 'mouse3rew', 'anticip', 'weight_after');

if current_wait == 2000
    punish_antic=1;
else
    punish_antic=0;
end

reward_alt=1;
current_stage = 2;
save(['os_data_figs/os' num2str(mouse_id) '/reference_oscc' num2str(mouse_id) '.mat'], ...
    'missed_trials', 'early_lick', 'early_lick', 'early_lick_trials_abs', 'current_wait', ...
    'left_trial_correct','right_trial_correct', 'punish_antic', ...
    'wait_increment', 'current_wait', 'reward_alt', 'current_stage');

left_trial_correct = left_trial_correct(1:find(left_trial_correct==9,1)-1);
right_trial_correct = right_trial_correct(1:find(right_trial_correct==9,1)-1);


saveas(gcf, ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_A2.fig'] );
saveas(gcf, ['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_A2.jpg'] );



correct_left = sum(left_trial_correct)/length(left_trial_correct)
correct_right = sum(right_trial_correct)/length(right_trial_correct)

try 
    d=sort(early_lick);
    median_early_lick = d( floor ( (length(early_lick_trials_delay)-sum(missed_trials))/2 ) )
end


% if n<(n_trials-175)
%     grape = (400-n)*.002;
%     disp(['please give about ' num2str(grape) ' grams of grape']);
% else
%     disp('no need to give grapes'); 
% end

    disp(['Mouse did ' num2str(n) ' trials']);
%     writePosition(serv,servo_near);