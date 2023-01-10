% For the dual lick working memory experiment
% 1st stage of training
% After licking any port, go cue sounds and water is provided
%% Clear and close all
close all; clear all; format compact;

%% Important parameters to set up
mouse_id = 1;
n_trials=400;
pre_tone_delay_dur=1200; % in milliseconds
response_dur = 4000; 
reward_dur_left_ms=15.1; 
reward_dur_right_ms=19.3;
current_waits = [179 174 129 135];
current_wait = current_waits(mouse_id); % 147 for oscc03, 150 for oscc01, 174 for oscc02
wait_increment=2;
wait_punish_time_out_dur = 800;
choice_punish_time_out_dur = 4000;

%% Initializing sounds
device=[];
InitializePsychSound(1);

wav_go = 'go_cue.wav';
wav_3kHz = 'tone3kHz5times.wav';
wav_12kHz = 'tone12kHz5times.wav';
wav_punish = 'white_noise_50ms.wav';

% Read WAV file from filesystem:
[y_go, freq_go] = psychwavread(wav_go);
wavedata_go = y_go';
[y_3kHz, freq_3kHz] = psychwavread(wav_3kHz);
wavedata_3kHz = y_3kHz';
[y_12kHz, freq_12kHz] = psychwavread(wav_12kHz);
wavedata_12kHz = y_12kHz';
[y_punish, freq_punish] = psychwavread(wav_punish);
wavedata_punish = y_punish';
nrchannels = size(wavedata_3kHz,1); % Number of rows == number of channels.

if nrchannels < 2
    wavedata_go = [wavedata_go ; wavedata_go];
    wavedata_3kHz = [wavedata_3kHz ; wavedata_3kHz];
    wavedata_12kHz = [wavedata_12kHz ; wavedata_12kHz];
    wavedata_punish = [wavedata_punish ; wavedata_punish];
    nrchannels = 2;
end

% Create virtual cards
pamaster = PsychPortAudio('Open', device, 9, 0, freq_go, nrchannels);
pa_go = PsychPortAudio('OpenSlave', pamaster);
pa_3kHz = PsychPortAudio('OpenSlave', pamaster);
pa_12kHz = PsychPortAudio('OpenSlave', pamaster);
pa_punish = PsychPortAudio('OpenSlave', pamaster);
t0 = PsychPortAudio('Start', pamaster, 0, 0, 1);

% Set volume
PsychPortAudio('Volume', pa_go, 0.5, [0.25; 0.25]);
PsychPortAudio('Volume', pa_3kHz, 0.5, [0.25; 0.25]);
PsychPortAudio('Volume', pa_12kHz, 0.5, [0.25; 0.25]);
PsychPortAudio('Volume', pa_punish, 0.5, [1.25; 1.25]);

% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', pa_go, wavedata_go);
PsychPortAudio('FillBuffer', pa_3kHz, wavedata_3kHz);
PsychPortAudio('FillBuffer', pa_12kHz, wavedata_12kHz);
PsychPortAudio('FillBuffer', pa_punish, wavedata_punish);

%% Set up raspberry pi
mypi = raspi();

% Asign and configure pins
pin_sens_left = 24;
pin_sens_right = 23;
pin_valv_left = 18;
pin_valv_right = 15;
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

%% Stats tracking variables
% total_trials = [];
early_lick_trials = []; % 1 if early lick, 0 otherwise
missed_trials = []; % 1 if missed, 0 otherwise
left_trial_correct = []; % 1 if correct, 0 if right is chosen instead of left
right_trial_correct = []; % otherwise 
current_tr=0;

%% Increment related variebles
early_lick = [];
last_10_missed=10; last_10_early=10;
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
state=TONE;

% Reward-related
left=1; right=-1;
current_cond=randsample([left right],1);
cond_count=0;
%% Start the task
n=0;
disp('starting the task');
% Start the 1st tone
if current_cond == left
    PsychPortAudio('Start', pa_12kHz, 1, 0, 0);
else 
    PsychPortAudio('Start', pa_3kHz, 1, 0, 0);
end
training_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
tone_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
% tic
figure(1); hold on; ylim([-0.2 11])

while n < n_trials
%for i=1:10000
    %% Detect lick
    % Shift values in the buffer by 1 position adding the previous reading
    % as the last, then compare the sum of it to the new value
    % Left
    for i=2:sens_buffer_len
        sens_buffer_left(i-1) = sens_buffer_left(i);
    end
    sens_buffer_left(sens_buffer_len) = sens_before_left;
    sens_now_left = readDigitalPin(mypi,pin_sens_left);
    if (sum(sens_buffer_left) == 0) && (sens_now_left == 1)
        lick_detected_left = 1;
    else
        lick_detected_left = 0;
    end
    sens_before_left = sens_now_left;
    
    % Right
    for i=2:sens_buffer_len
        sens_buffer_right(i-1) = sens_buffer_right(i);
    end
    sens_buffer_right(sens_buffer_len) = sens_before_right;
    sens_now_right = readDigitalPin(mypi,pin_sens_right);
    if (sum(sens_buffer_right) == 0) && (sens_now_right == 1)
        lick_detected_right = 1;
    else
        lick_detected_right = 0;
    end
    sens_before_right = sens_now_right;
   
    %% Pre-tone delay
    if state == PRE_TONE_DELAY
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % When delay is over, transition to sound and start the tone
        if milliseconds(time_now-pre_tone_delay_start)>=pre_tone_delay_dur
            state=TONE;
            % current_cond=randsample([left right],1);
            if mouse_id==4
                if cond_count >= 3
                    current_cond=-current_cond;
                    cond_count=0;
                end 
            else
                    current_cond=randsample([left right],1);
            end
            if current_cond == left
                PsychPortAudio('Start', pa_12kHz, 1, 0, 0);
            else 
                PsychPortAudio('Start', pa_3kHz, 1, 0, 0);
            end
            
            tone_start = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        
        elseif (lick_detected_left) | (lick_detected_right)
            PsychPortAudio('Start', pa_punish, 1, 0, 0);
            pause(0.05);
            PsychPortAudio('Stop', pa_punish);
            disp(['inbtw lick']);
            state = WAIT_PUNISHMENT_TIME_OUT;
            punish_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        
        end
    end
    
    %% Tone waiting out
    if state == TONE
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % After tone's time is over, stop it and transition to waiting for
        % licks
        if milliseconds(time_now - tone_start) >= current_wait
            early_lick_trials = [early_lick_trials 0];
            if length(early_lick_trials) >10
                current_tr = current_tr+1;
                last_10_early = sum( early_lick_trials(end-9:end) );
                disp(["early lick rate: " num2str( last_10_early )]);
                plot(current_tr, last_10_early, 'r*');
                xlim([0 current_tr+1]);
            end
            if current_cond == left
                PsychPortAudio('Stop', pa_12kHz);
            else
                PsychPortAudio('Stop', pa_3kHz);
            end
            state = RESPONSE;
            % Start playing go cue
            PsychPortAudio('Start', pa_go, 1, 0, 0);
            response_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        
        elseif (lick_detected_left) | (lick_detected_right)
            early_lick_trials = [early_lick_trials 1];
            if length(early_lick_trials) >10
                current_tr = current_tr+1;
                last_10_early = sum( early_lick_trials(end-9:end) );
                disp(["early lick rate: " num2str( last_10_early )]);
                plot(current_tr, last_10_early,'r*');
                xlim([0 current_tr+1]);
            end
            PsychPortAudio('Start', pa_punish, 1, 0, 0);
            pause(0.05);
            PsychPortAudio('Stop', pa_punish);
            if current_cond == left
                PsychPortAudio('Stop', pa_12kHz);
            else
                PsychPortAudio('Stop', pa_3kHz);
            end
            disp(['early lick: ' num2str(milliseconds(time_now-tone_start)) 'ms']);
            early_lick = [early_lick milliseconds(time_now-tone_start)];
            state = PRE_TONE_DELAY;
            pre_tone_delay_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
    end
    
    %% Punishment time out for not waiting
    if state == WAIT_PUNISHMENT_TIME_OUT
        if lick_detected_left | lick_detected_left
            PsychPortAudio('Start', pa_punish, 1, 0, 0);
            pause(0.05);
            PsychPortAudio('Stop', pa_punish);
            state = PRE_TONE_DELAY;
            pre_tone_delay_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
        
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % After punishment's time is over, stop it and transition to waiting for
        % licks
        if milliseconds(time_now-punish_start) >= (wait_punish_time_out_dur+randi(200))
            state = PRE_TONE_DELAY;
            pre_tone_delay_start = datetime( datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
    end
    
    %% Waiting for licks
    if state == RESPONSE
        if (current_cond==left) && (lick_detected_left==1)
            left_trial_correct = [left_trial_correct 1];
            if length(left_trial_correct) >=10
                last_10_left_corr = sum( left_trial_correct(end-9:end) );
                plot(current_tr, last_10_left_corr-.1,'g*');
                xlim([0 current_tr+1]);
            end
            state=REWARD;
            missed_trials = [missed_trials 0];
            if length(missed_trials) >10
                last_10_missed = sum( missed_trials(end-9:end) );
                plot(current_tr, last_10_missed+.1,'b*');
                xlim([0 current_tr+1]);
            end
        elseif (current_cond==left) && (lick_detected_right==1)
            left_trial_correct = [left_trial_correct 0];
            if length(left_trial_correct) >=10
                last_10_left_corr = sum( left_trial_correct(end-9:end) );
                plot(current_tr, last_10_left_corr-.1,'g*');
                xlim([0 current_tr+1]);
            end
            missed_trials = [missed_trials 0];
            if length(missed_trials) >10
                last_10_missed = sum( missed_trials(end-9:end) );
                plot(current_tr, last_10_missed+.1,'b*');
                xlim([0 current_tr+1]);
            end
            disp("licked right instead of left");
            
            state = CHOICE_PUNISHMENT_TIME_OUT;
            pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        elseif (current_cond==right) && (lick_detected_right==1) 
            right_trial_correct = [right_trial_correct 1];
            if length(right_trial_correct) >=10
                last_10_right_corr = sum( right_trial_correct(end-9:end) );
                plot(current_tr, last_10_right_corr-.1,'c*');
                xlim([0 current_tr+1]);
            end
            state=REWARD;
            missed_trials = [missed_trials 0];
            if length(missed_trials) >10
                last_10_missed = sum( missed_trials(end-9:end) );
                plot(current_tr, last_10_missed+.1,'b*');
                xlim([0 current_tr+1]);
            end
        elseif (current_cond==right) && (lick_detected_left==1)
            right_trial_correct = [right_trial_correct 0];
            if length(right_trial_correct) >=10
                last_10_right_corr = sum( right_trial_correct(end-9:end) );
                plot(current_tr, last_10_right_corr-.1,'c*');
                xlim([0 current_tr+1]);
            end
            missed_trials = [missed_trials 0];
            if length(missed_trials) >10
                last_10_missed = sum( missed_trials(end-9:end) );
                plot(current_tr, last_10_missed+.1,'b*');
                xlim([0 current_tr+1]);
            end
            disp("licked left instead of right");
            
            state = CHOICE_PUNISHMENT_TIME_OUT;
            pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
              'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        if milliseconds(time_now-response_start)>=response_dur
            missed_trials = [missed_trials 1];
            if length(missed_trials) >10
                last_10_missed = sum( missed_trials(end-9:end) );
                plot(current_tr, last_10_missed+.1,'b*');
                xlim([0 current_tr+1]);
            end
            disp("missed trial");
            state = PRE_TONE_DELAY;
            PsychPortAudio('Stop', pa_go);
            pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        end
    end
    
    %% Choice punishment
    if state== CHOICE_PUNISHMENT_TIME_OUT
        pause(3);
        state = PRE_TONE_DELAY;
    end
    
    %% Reward
    if state == REWARD
        n=n+1;
        cond_count=cond_count+1;
        if current_cond == left
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_left_ms*.001);
            writeDigitalPin(mypi,pin_valv_left,0);
            disp(['left lick detected, current wait: ' num2str(current_wait) 'ms; trial #' num2str(n) ]); 
        else
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_right_ms*.001);
            writeDigitalPin(mypi,pin_valv_right,0);
            disp(['right lick detected, current wait: ' num2str(current_wait) 'ms; trial #' num2str(n) ]);  
        end
        pause(3.5);
        PsychPortAudio('Stop', pa_go);
        state = PRE_TONE_DELAY;
        pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % increment the delay if the last 10 trials had 10% or less wait
        % and 10% or less missed trials
        incr_stabil=incr_stabil+1;
        if (last_10_missed<=1) & (last_10_early<=1)
            
            if incr_stabil>=10
                incr_stabil=0;
                current_wait=current_wait+wait_increment;
            end
        end
    end
    
    
    %% Decide if increment increase is needed
    
    
end
% toc

% Close the audio device:
PsychPortAudio('Stop', pamaster);
PsychPortAudio('Close', pa_go);
PsychPortAudio('Close', pa_3kHz);
PsychPortAudio('Close', pa_12kHz);
PsychPortAudio('Close', pamaster);

save(['dual_lick_correction_oscc0' num2str(mouse_id) '_' datestr(now,'dd-mm-yyyy_HH-MM') '.mat'], ...
    'missed_trials', 'early_lick', 'early_lick_trials', 'current_wait', ...
    'left_trial_correct','right_trial_correct', 'training_start', 'current_wait');


saveas(gcf, ['dual_lick_corr_fix_delay_oscc0' num2str(mouse_id) '_' datestr(now,'dd-mm-yyyy_HH-MM') '.fig']);
saveas(gcf, ['dual_lick_corr_fix_delay_oscc0' num2str(mouse_id) '_' datestr(now,'dd-mm-yyyy_HH-MM') '.jpg']);


wait_ratio = length(early_lick)/(length(early_lick_trials)-sum(missed_trials))
try 
    d=sort(early_lick);
    median_early_lick = d( floor ( (length(early_lick_trials)-sum(missed_trials))/2 ) )
end