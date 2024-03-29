
%% % Flush valves
% Since after some time withut use some air accumulates in the valves,
% Before running the training/experiments, valves need to be flushed 
% In case there is an erroneaus restart, save all the variables
warning('off', 'raspi:utils:SaveNotSupported')
save(['D:\dual_lick\backup\' datestr(now,'yyyy-mm-dd-_HH_MM_SS') '.mat']);
clear variables; close all;
% Set the time of flushing the valves; typical value for the 1 day of not 
% used is 33 seconds
dur_flush =33; 3;

pause_dur = 0.4;

% The pics for valves
pin_valve_l = 18; % 
pin_valve_r = 15; % 

% Initialize rasp
training_type = "A0";
rasp_init;

% Let's go!
tic
for i = 1:dur_flush
    writeDigitalPin(mypi,pin_valve_r,1);
    pause(pause_dur);
    writeDigitalPin(mypi,pin_valve_r,0);

    writeDigitalPin(mypi,pin_valve_l,1);
    pause(pause_dur);
    writeDigitalPin(mypi,pin_valve_l,0);
     
end
toc
