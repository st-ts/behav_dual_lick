%% Script to set up raspberry pi for A0s, A1, A2, A3 and B0, B3, B4


    try
        mypi = raspi('169.254.156.249', 'pi', 'raspberry');
    catch
        disp('so rasp was already setup hmm')
    end
    
% pin_servo = 14;
pin_sens_left = 24;
pin_sens_right = 23;
pin_valv_left = 18;
pin_valv_right = 15;
pin_ca_imaging = 26;
pin_siren_on = 21;
pin_punish_wait = 16;
configurePin(mypi,pin_sens_left,'DigitalInput');
configurePin(mypi,pin_sens_right,'DigitalInput');
configurePin(mypi,pin_punish_wait,'DigitalInput');
configurePin(mypi,pin_valv_left,'DigitalOutput');
configurePin(mypi,pin_valv_right,'DigitalOutput');
configurePin(mypi,pin_ca_imaging,'DigitalOutput');
configurePin(mypi,pin_siren_on,'DigitalOutput');
serv = servo(mypi, pin_servo);
servo_away = 100;
servo_near = 100;
writePosition(serv,servo_near);



    % Asign and configure pins

    pin_valv_left = 18;
    pin_valv_right = 15;
    pin_ca_imaging = 26;
    configurePin(mypi,pin_valv_left,'DigitalOutput');
    configurePin(mypi,pin_valv_right,'DigitalOutput');
    configurePin(mypi,pin_ca_imaging,'DigitalOutput');
    serv = servo(mypi, pin_servo);
    servo_away = 100;
    servo_near = 100;
    writePosition(serv,servo_near);
    
    % Asign and configure pins
    pin_servo_water = 14;
    pin_servo_laser = 25;
    pin_sens_left = 24;
    pin_sens_right = 23;
    pin_valves = 18;
    pin_laser = 20;
    pin_ca_imaging = 26;
    configurePin(mypi,pin_sens_left,'DigitalInput');
    configurePin(mypi,pin_sens_right,'DigitalInput');
    configurePin(mypi,pin_valves,'DigitalOutput');
    configurePin(mypi,pin_ca_imaging,'DigitalOutput');
    serv_water = servo(mypi, pin_servo_water);
    serv_laser = servo(mypi, pin_servo_laser);
    port_away = 75;
    port_near = 90;
    writePosition(serv_water,port_away);
    laser_blocked = 90;
    laser_open = 180;
    writePosition(serv_laser,laser_blocked);

end