
drops = 5;
pause(.164);
%% 

% Parameters for water delivery timing
t_btw =2.8;
reward_dur_left_ms = 9;
reward_dur_right_ms = 9;

% The pics for valves
pin_valve_l = 18; % 
pin_valve_r = 15; % 

% Initialize rasp
try
    mypi = raspi('169.254.156.249', 'pi', 'raspberry');
end

% Asign and configure pins
pin_servo = 14;
pin_sens_left = 24;
pin_sens_right = 23;
pin_valv_left = 18;
pin_valv_right = 15;
pin_ca_imaging = 26;
pin_siren_on = 21; 
configurePin(mypi,pin_siren_on,'DigitalOutput');
configurePin(mypi,pin_sens_left,'DigitalInput');
configurePin(mypi,pin_sens_right,'DigitalInput');
configurePin(mypi,pin_valv_left,'DigitalOutput');
configurePin(mypi,pin_valv_right,'DigitalOutput');
configurePin(mypi,pin_ca_imaging,'DigitalOutput');

%configurePin(mypi,pin_valve_r,'DigitalOutput');
% for i=1:6
%     disp('siren on');
%     writeDigitalPin(mypi,pin_siren_on,1);
%     pause(3);
%     disp('siren off');
%     writeDigitalPin(mypi,pin_siren_on,0);
%     pause(3);
% end



% Let's go test!
disp('go');
for i = 1:drops
    writeDigitalPin(mypi,pin_valve_r,1);
    pause(reward_dur_right_ms*0.001);
%     
    writeDigitalPin(mypi,pin_valve_r,0);
    pause(.1);

    pause(t_btw);

     writeDigitalPin(mypi,pin_valve_l,1);
    pause(reward_dur_left_ms*0.001);
    
    writeDigitalPin(mypi,pin_valve_l,0);
    
    pause(t_btw);
end


% Calibration results
% 200 iterations, target volume - 2.5nl, total - 0.5
% 17 Nov 2020: left: 15.1 ms -> .50; right: 19.3 ms -> 0.5
% 1 Feb 2021: left: 12.2 ms
