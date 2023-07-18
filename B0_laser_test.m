%% Laser test

close all; clear variables; format compact;

% Initialize Raspberry Pi
rasp_init;

% mypi = raspi('169.254.156.249', 'pi', 'raspberry');
% 
% % Asign and configure pins
% load('reference_rasp.mat'); % file with all the pin numbers and values for servo open / close
% 
% configurePin(mypi,pin_sens_left,'DigitalInput');
% configurePin(mypi,pin_sens_right,'DigitalInput');
% configurePin(mypi,pin_valv_left,'DigitalOutput');
% configurePin(mypi,pin_valv_right,'DigitalOutput');
% configurePin(mypi,pin_ca_imaging,'DigitalOutput');
% configurePin(mypi,pin_laser,'DigitalOutput');
% % serv = servo(mypi, pin_servo);
% servo_las_L = servo(mypi, pin_servo_laser_L);
% servo_las_R = servo(mypi, pin_servo_laser_R);


for i=1:6
    % Left
    writePosition(servo_las_L,servo_las_open_L);
    pause(1);
    writePosition(servo_las_L,servo_las_closed_L);
    pause(1);

    % Right
    writePosition(servo_las_R,servo_las_open_R);
    pause(1);
    writePosition(servo_las_R,servo_las_closed_R);
    pause(1);
end