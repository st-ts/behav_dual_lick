% For the dual lick working memory experiment
% 1st stage of training
% After licking any port, go cue sounds and water is provided
%% Clear and close all
close all; clear all; format compact;

%% Important parameters to set up
mouse_id = 1; 
n_trials = 400; 
max_tries = ceil(n_trials*2); 
imaged_trials = 100; 
pre_tone_delay_dur=4500; % in milliseconds
response_dur = 3000; 
load(['valves_calibrated.mat']);
punish_antic = 0; 
%load(['reference_oscc' num2str(mouse_id) '.mat']); 
current_wait=0; 
wait_increment=0; 
tone_duration = 1150; 
max_missed_tr = 14;

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
device=[];
InitializePsychSound(1);

wav_go = 'go_cue.wav';
wav_3kHz = 'tone3kHz5times.wav';
wav_12kHz = '10khz_sound.wav';
wav_punish = 'white_noise_50ms.wav';
wav_end = "cat-meow_115bpm.wav";

% Read WAV file from filesystem:
[y_go, freq_go] = psychwavread(wav_go);
wavedata_go = y_go';
[y_3kHz, freq_3kHz] = psychwavread(wav_3kHz);
wavedata_3kHz = y_3kHz';
[y_12kHz, freq_12kHz] = psychwavread(wav_12kHz);
wavedata_12kHz = y_12kHz';
[y_punish, freq_punish] = psychwavread(wav_punish);
wavedata_punish = y_punish';
[y_end, freq_end] = psychwavread(wav_end);
wavedata_end = y_end';
nrchannels = size(wavedata_3kHz,1); % Number of rows == number of channels.

if nrchannels < 2
    wavedata_go = [wavedata_go ; wavedata_go];
    wavedata_3kHz = [wavedata_3kHz ; wavedata_3kHz];
    wavedata_12kHz = [wavedata_12kHz ; wavedata_12kHz];
    wavedata_punish = [wavedata_punish ; wavedata_punish];
    wavedata_end = [wavedata_end ; wavedata_end];
    nrchannels = 2;
end

% Create virtual cards
pamaster = PsychPortAudio('Open', device, 9, 0, freq_go, nrchannels);
pa_go = PsychPortAudio('OpenSlave', pamaster);
pa_3kHz = PsychPortAudio('OpenSlave', pamaster);
pa_12kHz = PsychPortAudio('OpenSlave', pamaster);
pa_punish = PsychPortAudio('OpenSlave', pamaster);
pa_end = PsychPortAudio('OpenSlave', pamaster);
t0 = PsychPortAudio('Start', pamaster, 0, 0, 1);

% Set volume
PsychPortAudio('Volume', pa_go, 0.5, [0.05; 0.05]);
PsychPortAudio('Volume', pa_3kHz, 0.5, [0.04; 0.04]);
PsychPortAudio('Volume', pa_12kHz, 0.5, [0.02; 0.02]);
PsychPortAudio('Volume', pa_punish, 0.5, [1.25; 1.25]);
PsychPortAudio('Volume', pa_end, 0.5, [0.25; 0.25]);

% Fill the audio playback buffer with the audio data 'wavedata':
PsychPortAudio('FillBuffer', pa_go, wavedata_go);
PsychPortAudio('FillBuffer', pa_3kHz, wavedata_3kHz);
PsychPortAudio('FillBuffer', pa_12kHz, wavedata_12kHz);
PsychPortAudio('FillBuffer', pa_punish, wavedata_punish);
PsychPortAudio('FillBuffer', pa_end, wavedata_end);

%% Time logging related variables
left_lick_times = [];
right_lick_times = [];
left_tone_times = zeros(1,max_tone_n);
right_tone_times = zeros(1,max_tone_n);
current_waits = zeros(1,n_trials);
trial_order = ones(1,max_tone_n)*3;

%% Monitor anticipatory licking
anticip = [];
lick_1st = 1;

%% Set up raspberry pi
mypi = raspi();

% Asign and configure pins
pin_sens_left = 24;
pin_sens_right = 23;
pin_valv_left = 18;
pin_valv_right = 15;
pin_ca_imaging = 26;
configurePin(mypi,pin_sens_left,'DigitalInput');
configurePin(mypi,pin_sens_right,'DigitalInput');
configurePin(mypi,pin_valv_left,'DigitalOutput');
configurePin(mypi,pin_valv_right,'DigitalOutput');
configurePin(mypi,pin_ca_imaging,'DigitalOutput');

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
missed_trials = []; % 1 if missed, 0 otherwise
left_trial_correct = []; % 1 if correct, 0 if right is chosen instead of left
right_trial_correct = []; % otherwise 
too_many_trials_missed=0;

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
WAIT_PUNISHMENT_TIME_OUT = 7;
CHOICE_PUNISHMENT_TIME_OUT = 8;
FIRST_TRIAL = 9;
REWARD_INTAKE = 10;
WORKING_MEMORY = 11;
state=FIRST_TRIAL;

% Reward-related
left=1; right=-1;
current_cond=randsample([left right],1);
cond_count=0;


%% Start the task
n=0;
disp('starting the task');
% Start the task
training_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
writeDigitalPin(mypi,pin_ca_imaging,1);
pre_tone_delay_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
figure(1); hold on; ylim([-0.2 11])
calibr = 1;



t1 = PsychPortAudio('Start', pa_go, 1, 0, 0);
        pause(0.1);
        PsychPortAudio('Stop', pa_go);

        writeDigitalPin(mypi,pin_valv_right,0);
            writeDigitalPin(mypi,pin_valv_right,0);
        %     
            writeDigitalPin(mypi,pin_valv_left,0);
            writeDigitalPin(mypi,pin_valv_left,0);
        pause(2);
        t1 = PsychPortAudio('Start', pa_3kHz, 1, 0, 0);
        pause(0.1);
        PsychPortAudio('Stop', pa_3kHz);

        for i = 1:100
            writeDigitalPin(mypi,pin_valv_right,1);
            pause(reward_dur_right_ms*0.001);
            writeDigitalPin(mypi,pin_valv_right,0);
        %     
            writeDigitalPin(mypi,pin_valv_left,1);
            pause(reward_dur_left_ms*0.001);
            writeDigitalPin(mypi,pin_valv_left,0);

            pause(.3);
            
            % detect
            for i=2:sens_buffer_len
                sens_buffer_left(i-1) = sens_buffer_left(i);
            end
    sens_buffer_left(sens_buffer_len) = sens_before_left;
    sens_now_left = readDigitalPin(mypi,pin_sens_left);
    if (sum(sens_buffer_left) == 0) && (sens_now_left == 1)
        lick_detected_left = 1;
        left_lick_time = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        left_lick_times = [left_lick_times milliseconds(training_start-left_lick_time)];
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
        right_lick_time = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        right_lick_times = [right_lick_times milliseconds(training_start-right_lick_time)];
    else
        lick_detected_right = 0;
    end
    sens_before_right = sens_now_right;
   
   
        
        end

    
%for i=1:10000
    


% Play end tone
PsychPortAudio('Start', pa_end, 1, 0, 0);
pause(4);
PsychPortAudio('Stop', pa_end);

% Close the audio device:
PsychPortAudio('Stop', pamaster);
PsychPortAudio('Close', pa_go);
PsychPortAudio('Close', pa_3kHz);
PsychPortAudio('Close', pa_12kHz);
PsychPortAudio('Close', pa_end);
PsychPortAudio('Close', pamaster);
% toc

if mouse3rew == 1
    if wait_increment==0
        training_type = 'inagaki, licking during the sound is not punished, discrim learning 3rew switch';
    else
        training_type = 'inagaki extending the delay after the sound, licking during the sound is not punished until the delay is 1200ms, 3rew switch';
    end
else
    if wait_increment==0
        training_type = 'inagaki, licking during the sound is not punished, discrim learning random';
    else
        training_type = 'inagaki extending the delay after the sound, licking during the sound is not punished until the delay is 1200ms';
    end
end



post_note = input(["Weight of the bottle? \n:"]);
