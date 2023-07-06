

% Flush valves
clear all; close all;
% Parameters to test
pause_dur = 0.4;

% The pics for valves
pin_valve_l = 18; % 
pin_valve_r = 15; % 

% Initialize rasp
mypi = raspi();
%configurePin(mypi,pin_valve_r,'DigitalOutput');

% Let's go!
tic
for i = 1:25
    writeDigitalPin(mypi,pin_valve_r,1);
    pause(pause_dur);
    writeDigitalPin(mypi,pin_valve_r,0);

    writeDigitalPin(mypi,pin_valve_l,1);
    pause(pause_dur);
    writeDigitalPin(mypi,pin_valve_l,0);
     
end
toc




