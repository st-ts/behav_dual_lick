%% Initializing sounds

try
    % Close the audio device:
    PsychPortAudio('Stop', pamaster);
    PsychPortAudio('Close', pa_go);
    PsychPortAudio('Close', pa_low);
    PsychPortAudio('Close', pa_high);
    PsychPortAudio('Close', pa_end);
    PsychPortAudio('Close', pa_ambig);
    PsychPortAudio('Close', pamaster);
catch
    1;
end

    devices = PsychPortAudio('GetDevices');
% Create a sample struct array
S = struct('Kek', {'we', 'abc', 'we', 'xyz'}, 'lol', {'ab', 'po', 'po', 'po'});

% Find the row number(s) where "Kek" is "we" and "lol" is "po"
deviceRow = find(strcmp({devices.HostAudioAPIName}, 'Windows WASAPI') & strcmp({devices.DeviceName}, 'Speakers (High Definition Audio Device)'));
device = devices(deviceRow).DeviceIndex;
% Display the row number(s)



    InitializePsychSound(1);
    
    % choose sounds
    wav_go = 'sounds/go_cue.wav';
    wav_low = 'sounds/tone3kHz5times.wav';
    wav_high = 'sounds/tone10kHz150ms.wav';
    wav_end = "sounds/end_exper.wav";
%     wav_ambig = "tone_5370Hz.wav";
    wav_ambig =  "sounds/ambig.wav";
    % Read WAV file from filesystem:
    [y_go, freq_go] = psychwavread(wav_go);
    wavedata_go = y_go';
    [y_low, freq_low] = psychwavread(wav_low);
    wavedata_low = y_low';
    [y_high, freq_high] = psychwavread(wav_high);
    wavedata_high = y_high';
    [y_end, freq_end] = psychwavread(wav_end);
    wavedata_end = y_end';
    [y_ambig, freq_ambig] = psychwavread(wav_ambig);
    wavedata_ambig = y_ambig';
    nrchannels = size(wavedata_low,1); % Number of rows == number of channels.

    if nrchannels < 2
        wavedata_go = [wavedata_go ; wavedata_go];
        wavedata_low = [wavedata_low ; wavedata_low];
        wavedata_high = [wavedata_high ; wavedata_high];
        wavedata_end = [wavedata_end ; wavedata_end];
        wavedata_ambig = [wavedata_ambig ; wavedata_ambig];
        nrchannels = 2;
    end

    % Create virtual cards
%     pamaster = PsychPortAudio('Open', 6, 9, 0, freq_go, nrchannels);
% pamaster = PsychPortAudio('Open', 6);
pamaster = PsychPortAudio('Open', device, 9); %, 9, 0);
    pa_go = PsychPortAudio('OpenSlave', pamaster);
    pa_low = PsychPortAudio('OpenSlave', pamaster);
    pa_high = PsychPortAudio('OpenSlave', pamaster);
    pa_end = PsychPortAudio('OpenSlave', pamaster);
    pa_ambig = PsychPortAudio('OpenSlave', pamaster);
    t0 = PsychPortAudio('Start', pamaster, 0, 0, 1);
    
    % Set volume
    PsychPortAudio('Volume', pa_go, 0.5, [0.05; 0.05]);
    PsychPortAudio('Volume', pa_low, 0.5, [0.12; 0.0]);
    PsychPortAudio('Volume', pa_high, 0.5, [0.0; 0.09]);
    PsychPortAudio('Volume', pa_end, 0.5, [0.1; 0.1]);
    PsychPortAudio('Volume', pa_ambig, 0.5, [0.12; 0.09]);
    
    % Fill the audio playback buffer with the audio data 'wavedata':
    PsychPortAudio('FillBuffer', pa_go, wavedata_go);
    PsychPortAudio('FillBuffer', pa_low, wavedata_low);
    PsychPortAudio('FillBuffer', pa_high, wavedata_high);
    PsychPortAudio('FillBuffer', pa_end, wavedata_end);     
    PsychPortAudio('FillBuffer', pa_ambig, wavedata_ambig);




