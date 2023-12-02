%% Set up raspberry pi 
% Initalize the pins for all the experiments, and set the values for the
% servo motors
% mypi = raspi('169.254.156.249', 'pi', 'raspberry');
mypi = raspi();


% Asign and configure pins
pin_servo_water = 14;
pin_servo_laser_L = 12;
pin_servo_laser_R = 6;
pin_sens_left = 24;
pin_sens_right = 23;
pin_valv_left = 18;
pin_valv_right = 15;

% TONES
pin_tone_go = 26;
pin_tone_left = 19;
pin_tone_right = 13;

pin_laser = 20;
% % pin21 used to be "siren on" pin_siren_on = 21; now it's "ca imaging"
pin_ca_imaging = 21; %%
pin_punish_wait = 16;
port_away = 100; 165; 49;
port_near = 141; 180; 65;
servo_las_open_L = 120;
servo_las_closed_L = 180;
servo_las_open_R = 90;
servo_las_closed_R = 40;

% %  configure pins

configurePin(mypi,pin_sens_left,'DigitalInput');
configurePin(mypi,pin_sens_right,'DigitalInput');
configurePin(mypi,pin_valv_left,'DigitalOutput');
configurePin(mypi,pin_valv_right,'DigitalOutput');

configurePin(mypi,pin_laser,'DigitalOutput');
configurePin(mypi,pin_ca_imaging,'DigitalOutput');
% tones 
configurePin(mypi,pin_tone_go,'DigitalOutput');
configurePin(mypi,pin_tone_left,'DigitalOutput');
configurePin(mypi,pin_tone_right,'DigitalOutput');

servo_water = servo(mypi, pin_servo_water);
servo_las_L = servo(mypi, pin_servo_laser_L);
servo_las_R = servo(mypi, pin_servo_laser_R);

writePosition(servo_water,port_near);


% Set  up the anterior-posterior stepper motor if it is used in the scipt
if training_type == 'B1'
    a = arduino('COM5','Uno','Libraries','Adafruit\MotorShieldV2');
    shield = addon(a,'Adafruit\MotorShieldV2');
    addrs = scanI2CBus(a,0);
    y_motor = stepper(shield,2,200)
    y_motor.RPM = 1000;
    y_move = 1000;
end
