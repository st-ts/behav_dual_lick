% For the dual lick working memory experiment
% 1st stage of training
% After licking any port, go cue sounds and water is provided
%% Clear and close all
close all; clear all; format compact;
%% Important parameters to set up
n_trials=350;
mouse_id = input('Mouse id\n:'); 

pause_after_rew = .8; 

reward_dur_ms = 5;

% Freebies
freebie_max = 20; freebie_n = 0; freebie_t = 12;
max_idle_sec = 90;

%% Initializing sounds
sound_init;


% Switch
left_rewards = zeros(1,n_trials);
right_rewards = zeros(1,n_trials);


%% Keeping track of licking
%% Time logging related variables
max_tone_n = 2000;
left_lick_times = zeros(1,max_tone_n*7); 
right_lick_times = zeros(1,max_tone_n*7); 
lick_n_L = 0;
lick_n_R= 0;
% left_lick_times = [];
% right_lick_times = [];


%% Set up raspberry pi
mypi = raspi('169.254.156.249', 'pi','raspberry');

load('D:/dual_lick/reference_rasp.mat'); % file with all the pin numbers and values for servo open / close

configurePin(mypi,pin_sens_left,'DigitalInput');
configurePin(mypi,pin_sens_right,'DigitalInput');
configurePin(mypi,pin_valv_left,'DigitalOutput');
configurePin(mypi,pin_valv_right,'DigitalOutput');

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

%% Ask about training info
weight = input(['Mouse ' num2str(mouse_id) ' weight \n:']);
pre_note = input("Anything special before the experiment? \n:");
    

% To make sure there's no sudden flash at the beginning
writeDigitalPin(mypi,pin_valv_right,0);
writeDigitalPin(mypi,pin_valv_right,0);
%     
writeDigitalPin(mypi,pin_valv_left,0);
writeDigitalPin(mypi,pin_valv_left,0);

%% Starting the task

lick_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
n=1;
disp(['starting the task, time: ' datestr(now,'dd-mm-yyyy HH:MM:SS.FFF')]);
training_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

%% Loop for n iterations
too_idle =0;
while n < n_trials && ~too_idle
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
%     end
%     sens_before_right = sens_now_right;
    scr_detect_lick;



   
    %% Play go cue if lick detected
%    % Left
    if lick_detected_left
        
        % play the sound
        if n > 12 & sum(left_rewards(n-12:n-1))>3*sum(right_rewards(n-12:n-1))
            disp('futile left lick');
            lick_detected_left=0;
        else
            t1 = PsychPortAudio('Start', pa_go, 1, 0, 0);
            pause(0.1);
            PsychPortAudio('Stop', pa_go);
            lick_detected_left=0;
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
            pause(0.1);
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
            disp(['left lick detected, cue played, reward given #' num2str(n) ]);
            lick_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            left_lick_times = [left_lick_times milliseconds(lick_t - training_start)];
            left_rewards(n)=1;
            n=n+1;

            pause(pause_after_rew);
        end
    end
    
    % Right
    if lick_detected_right
        if n > 12 & sum(right_rewards(n-12:n-1))>3*sum(left_rewards(n-12:n-1))
            disp('futile right lick');
            lick_detected_right=0;
        else
            % play the sound
            t1 = PsychPortAudio('Start', pa_go, 1, 0, 0);
            pause(0.1);
            PsychPortAudio('Stop', pa_go);
            lick_detected_right=0;
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
            pause(0.1);
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);

            lick_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            disp(['right lick detected, cue played, reward given #' num2str(n) ]);
            right_lick_times = [right_lick_times milliseconds(lick_t - training_start)];
            right_rewards(n)=1;
            n=n+1;
    
            pause(pause_after_rew);
        end
    end
    
    current_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
    % If mouse doesn't do anything for 20 seconds, give a freebie
    if seconds(current_t - lick_t) > freebie_t  && freebie_n < freebie_max
        freebie_n = freebie_n + 1;
        lick_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        n=n+1;
        t1 = PsychPortAudio('Start', pa_go, 1, 0, 0);
        pause(0.1);
        PsychPortAudio('Stop', pa_go);
        if sum(right_rewards(1:n)) <= sum(left_rewards(1:n))
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
            disp(['right freebie #' num2str(freebie_n) ', reward given #' num2str(n) ]);
            right_rewards(n)=1;
        else
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
            disp(['left freebie #' num2str(freebie_n) ', reward given #' num2str(n) ]);
            left_rewards(n)=1;
        end
    end

    % Too long idle - stop run
    if seconds(current_t - lick_t) > max_idle_sec
        too_idle = 1;
    end


    
end

% tic
% for n =1:100
%     clock;
%     sens_buffer(buffer_count) = readDigitalPin(a,pin_sens);
% end
% toc
% Close the audio device:
% % Play end tone & close the audio device:
sound_end;


% Compute

training_end = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
training_duration = training_end - training_start;
disp(['training duration: ' datestr(training_duration,'HH:MM:SS.FFF')]);

post_note = input(["Anything special after the experiment? \n:"]);
weight_after = input(['Mouse ' num2str(mouse_id) ' weight after \n:']);

if ~exist(['os_data_figs/os' num2str(mouse_id) ], 'dir')
       mkdir(['os_data_figs/os' num2str(mouse_id) ]);
end


% Truncate
left_lick_times = left_lick_times(1:lick_n_L);
right_lick_times = right_lick_times(1:lick_n_R);

% Save
save(['os_data_figs/os' num2str(mouse_id) '/os' num2str(mouse_id) '_' datestr(now,'yy-mm-dd_HH-MM') '_A1.mat'], ...
    'left_lick_times', 'right_lick_times', 'weight', 'freebie_n', ...
    'pre_note', 'post_note', 'weight_after');




