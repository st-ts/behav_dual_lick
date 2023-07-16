%% Set up raspberry pi 
% Initalize the pins for all the experiments, and set the values for the
% servo motors
mypi = raspi('169.254.156.249', 'pi', 'raspberry');

% Asign and configure pins
pin_servo_water = 14;
pin_servo_laser_L = 12;
pin_servo_laser_R = 6;
pin_sens_left = 24;
pin_sens_right = 23;
pin_valv_left = 18;
pin_valv_right = 15;
pin_ca_imaging = 26;
pin_laser = 20;
% pin21 used to be "siren on" pin_siren_on = 21; now it's "laser on"
pin_laser_on = 21;
pin_punish_wait = 16;
port_away = 49;
port_near = 65;
servo_las_open_L = 120;
servo_las_closed_L = 180;
servo_las_open_R = 90;
servo_las_closed_R = 40;

% %  configure pins

configurePin(mypi,pin_sens_left,'DigitalInput');
configurePin(mypi,pin_sens_right,'DigitalInput');
configurePin(mypi,pin_valv_left,'DigitalOutput');
configurePin(mypi,pin_valv_right,'DigitalOutput');
configurePin(mypi,pin_ca_imaging,'DigitalOutput');
configurePin(mypi,pin_laser,'DigitalOutput');
serv = servo(mypi, pin_servo_water);
servo_las_L = servo(mypi, pin_servo_laser_L);
servo_las_R = servo(mypi, pin_servo_laser_R);

