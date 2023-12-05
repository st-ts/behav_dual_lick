% For the dual lick working memory experiment
% 1st stage of training
% After licking any port, go cue sounds and water is provided
% In case there is an erroneaus restart, save all the variables
warning('off', 'raspi:utils:SaveNotSupported')
save(['D:\dual_lick\backup\' datestr(now,'yyyy-mm-dd-_HH_MM_SS') '.mat']);
%% Clear and close all
close all; clear all; format compact;
%% Important parameters to set up
n_trials=350;
mouse_id = input('Mouse id\n:'); 

pause_after_rew = 1.5; 

reward_dur_ms = 5;

% Freebies
freebie_max = 20; freebie_n = 0; freebie_t = 12;
max_idle_sec = 60;


% Switch
left_rewards = zeros(1,n_trials);
right_rewards = zeros(1,n_trials);


%% Keeping track of licking
%% Time logging related variables
max_tone_n = 2000;
left_rew_times = []; 
right_rew__times = [];         
lick_n_L = 0;
lick_n_R= 0;
left_lick_times = [];
right_lick_times = [];

%% hmm
training_type = 'A1'; 

%% Set up raspberry pi
rasp_init;
% mypi = raspi('169.254.156.249', 'pi','raspberry');
% 
% load('D:/dual_lick/reference_rasp.mat'); % file with all the pin numbers and values for servo open / close
% 
% configurePin(mypi,pin_sens_left,'DigitalInput');
% configurePin(mypi,pin_sens_right,'DigitalInput');
% configurePin(mypi,pin_valv_left,'DigitalOutput');
% configurePin(mypi,pin_valv_right,'DigitalOutput');

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
pre_note = input("Anything special before the experiment? \n:", "s");
    

% To make sure there's no sudden flash at the beginning
writeDigitalPin(mypi,pin_valv_right,0);
writeDigitalPin(mypi,pin_valv_right,0);
%     
writeDigitalPin(mypi,pin_valv_left,0);
writeDigitalPin(mypi,pin_valv_left,0);

%% Starting the task
rew_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
n=1;
disp(['starting the task, time: ' datestr(now,'dd-mm-yyyy HH:MM:SS.FFF')]);
training_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

%% Loop for n iterations
too_idle =0;
while n < n_trials && ~too_idle
   
    scr_detect_lick;
   
    %% Play go cue if lick detected
%    % Left
    if lick_detected_left
        
        % play the sound
        if n > 12 & sum(left_rewards(n-12:n-1))>3*sum(right_rewards(n-12:n-1))
            disp('futile left lick');
            lick_detected_left=0;
        else
            rew_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            % play the GO sound
            send_rasp_pulse(mypi, pin_tone_go,10);
            pause(0.05);
            send_rasp_pulse(mypi, pin_tone_go,10);

            lick_detected_left=0;



            disp(['left lick detected, cue played, reward given #' num2str(n) ]);
            
            left_rew_times = [left_rew_times milliseconds(rew_t - training_start)];
            left_rewards(n)=1;
            n=n+1;
            send_rasp_pulse(mypi, pin_valv_left,2);

            pause(pause_after_rew);
        end
    end
    
    % Right
    if lick_detected_right
        if n > 12 & sum(right_rewards(n-12:n-1))>3*sum(left_rewards(n-12:n-1))
            disp('futile right lick');
            lick_detected_right=0;
        else
            rew_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            % play the GO sound
            send_rasp_pulse(mypi, pin_tone_go,10);
            pause(0.05);
send_rasp_pulse(mypi, pin_valv_right,10);
            lick_detected_right=0;
            

            
            disp(['right lick detected, cue played, reward given #' num2str(n) ]);
            right_rew__times = [right_rew__times milliseconds(rew_t - training_start)];
            right_rewards(n)=1;
            n=n+1;
    
            pause(pause_after_rew);
        end
    end
    
    current_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
    % If mouse doesn't do anything for 20 seconds, give a freebie
    if seconds(current_t -  rew_t) > freebie_t  && freebie_n < freebie_max
        freebie_n = freebie_n + 1;
        rew_t = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        n=n+1;
        % play the GO sound
        send_rasp_pulse(mypi, pin_tone_go,10);
        pause(0.08);

        if sum(right_rewards(1:n)) <= sum(left_rewards(1:n))
            send_rasp_pulse(mypi, pin_valv_right,2);

            disp(['right freebie #' num2str(freebie_n) ', reward given #' num2str(n) ]);
            right_rewards(n)=1;
            right_rew__times = [right_rew__times milliseconds(rew_t - training_start)];
        else
            send_rasp_pulse(mypi, pin_valv_left,2);
            disp(['left freebie #' num2str(freebie_n) ', reward given #' num2str(n) ]);
            left_rewards(n)=1;
            left_rew__times = [right_rew__times milliseconds(rew_t - training_start)];
        end
    end

    % Too long idle - stop run
    if seconds(current_t - rew_t) > max_idle_sec
        too_idle = 1;
    end


    
end

% tic
% for n =1:100
%     clock;
%     sens_buffer(buffer_count) = readDigitalPin(a,pin_sens);
% end
% toc


%% Play end tone & close the audio device:
% Initializing sounds
sound_init;
sound_end;


% Compute

training_end = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
training_duration = training_end - training_start;
disp(['training duration: ' datestr(training_duration,'HH:MM:SS.FFF')]);

post_note = input(["Anything special after the experiment? \n:"], "s");
weight_after = input(['Mouse ' num2str(mouse_id) ' weight after \n:']);

if ~exist(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) ], 'dir')
       mkdir(['D:/dual_lick/os_data_figs/os' num2str(mouse_id) ]);
end



%% Data for saving the file

save_behav_all;
