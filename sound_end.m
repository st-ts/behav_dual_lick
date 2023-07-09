% Script ofr the sound at the end of the experiment

% Play end tone
PsychPortAudio('Start', pa_end, 1, 0, 0);
pause(4);
PsychPortAudio('Stop', pa_end);

% Close the audio device:
PsychPortAudio('Stop', pamaster);
PsychPortAudio('Close', pa_go);
PsychPortAudio('Close', pa_low);
PsychPortAudio('Close', pa_high);
PsychPortAudio('Close', pa_end);
PsychPortAudio('Close', pa_ambig);
PsychPortAudio('Close', pamaster);


