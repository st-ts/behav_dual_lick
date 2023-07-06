clear variables; close all;

mouse_id = input('Mouse id\n:'); 



%% Set up raspberry pi
mypi = raspi('169.254.156.249', 'pi', 'raspberry');

% % Asign and configure pins
load('reference_rasp.mat'); % file with all the pin numbers and values for servo open / close
% pin_servo_water = 14;
% pin_servo_laser = 25;
% pin_sens_left = 24;
% pin_sens_right = 23;
% pin_valves = 18;
% pin_laser = 21;
% pin_ca_imaging = 26;
% port_away = 75;
% port_near = 90;
% laser_blocked = 90;
% laser_open = 180;

configurePin(mypi,pin_sens_left,'DigitalInput');
configurePin(mypi,pin_sens_right,'DigitalInput');
configurePin(mypi,pin_valv_both,'DigitalOutput');
configurePin(mypi,pin_ca_imaging,'DigitalOutput');
serv_water = servo(mypi, pin_servo_water);
serv_laser_L = servo(mypi, pin_servo_laser_L);
serv_laser_R = servo(mypi, pin_servo_laser_R);


% Set all the servos in a ready position
writePosition(serv_water,port_away);
writePosition(serv_laser_L,servo_las_closed_L);
writePosition(serv_laser_R,servo_las_closed_R);

%% idk how to name this
laser_stim_sec = 1;



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
left_lick_times = [];
right_lick_times = [];

%% States
PRE_STIM = 1;
PORT_MOVE = 2;
INBTW_STIM_PORT = 3;
STIM_LASER = 4;
STIM_LASER_WAIT = 5;
state = PRE_STIM;
inbtw_range = [3500, 4000];
pre_range = [1500 2000];
pre_period  = randi(pre_range);
inbtw_period = randi(inbtw_range);
laser_dur = 1150;

%% Trial order;
tr_per_cond = 35; n_cond = 6;
laser_stim_seq = [ones(1,tr_per_cond*n_cond/2) zeros(1,tr_per_cond*n_cond/2) ];
water_seq = [zeros(1,tr_per_cond) ones(1,tr_per_cond) 2*ones(1,tr_per_cond) ...
             zeros(1,tr_per_cond) ones(1,tr_per_cond) 2*ones(1,tr_per_cond) ];

trial_order = randperm(tr_per_cond*n_cond);
curr_tr = 1;


%% Start imaging
time_imag_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
time_stim_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
writeDigitalPin(mypi,pin_ca_imaging,1);
pause(.1);
writeDigitalPin(mypi,pin_ca_imaging,0);
pause(3);


%% Running the trials
t_stims = zeros(1, tr_per_cond*n_cond);
t_port_move = zeros(1, tr_per_cond*n_cond);

time_pre_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
t_port_move(curr_tr) = milliseconds(time_pre_start-time_imag_start);
    if water_seq(trial_order(curr_tr)) == 1
        writePosition(serv_water,port_near);
    else
        writePosition(serv_water,port_away);
    end
    if laser_stim_seq(trial_order(curr_tr)) == 1
        writePosition(serv_laser_L,servo_las_open_L);
        writePosition(serv_laser_R,servo_las_open_R);
    else
        writePosition(serv_laser_L,servo_las_closed_L);
        writePosition(serv_laser_R,servo_las_closed_R);
    end


while curr_tr <= tr_per_cond * n_cond 
    %% Detect licks
    for i=2:sens_buffer_len
        sens_buffer_left(i-1) = sens_buffer_left(i);
    end
    sens_buffer_left(sens_buffer_len) = sens_before_left;
    sens_now_left = readDigitalPin(mypi,pin_sens_left);
    if (sum(sens_buffer_left) == 0) && (sens_now_left == 1)
        lick_detected_left = 1;
        left_lick_time = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        left_lick_times = [left_lick_times milliseconds(left_lick_time - time_imag_start)];
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
        right_lick_times = [right_lick_times milliseconds(right_lick_time - time_imag_start)];
    else
        lick_detected_right = 0;
    end
    sens_before_right = sens_now_right;

%% States

    if state == PRE_STIM
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        % When delay is over, transition to sound and start the tone
        if milliseconds(time_now-time_pre_start)>=pre_period
            state=STIM_LASER;
            
            
            pre_period = randi(pre_range);
        end

    
    elseif state == STIM_LASER
        disp(['trial ' num2str(curr_tr) ', water ' num2str(water_seq(trial_order(curr_tr))) ...
               ', laser ' num2str(laser_stim_seq(trial_order(curr_tr)))])
        time_stim_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        t_stims(curr_tr) = milliseconds(time_stim_start-time_imag_start);
        writeDigitalPin(mypi,pin_laser,1);
        pause(0.02);
        writeDigitalPin(mypi,pin_laser,0);
        
        state = STIM_LASER_WAIT;


    elseif state == STIM_LASER_WAIT
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        if milliseconds(time_now-time_stim_start)>=laser_dur 
            state = INBTW_STIM_PORT;
            time_inbtw_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            if water_seq(trial_order(curr_tr)) == 2
                writeDigitalPin(mypi,pin_valv_both,1);
                pause(0.02);
                writeDigitalPin(mypi,pin_valv_both,0);
                pause(0.2);
                writeDigitalPin(mypi,pin_valv_both,1);
                pause(0.02);
                writeDigitalPin(mypi,pin_valv_both,0);
            end
        end

    
    elseif state == INBTW_STIM_PORT
        time_now = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
        if milliseconds(time_now-time_inbtw_start)>=inbtw_period
            state = PORT_MOVE;
            time_pre_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
            t_port_move(curr_tr) = milliseconds(time_pre_start-time_imag_start); 
            curr_tr = curr_tr+1;
            inbtw_period = randi(inbtw_range);
        end

    elseif state == PORT_MOVE
        if water_seq(trial_order(curr_tr)) == 0
            writePosition(serv_water,port_away);
        else
            writePosition(serv_water,port_near);
        end
        if laser_stim_seq(trial_order(curr_tr)) == 1
            writePosition(serv_laser_L,servo_las_open_L);
            writePosition(serv_laser_R,servo_las_open_R);
        else
            writePosition(serv_laser_L,servo_las_closed_L);
            writePosition(serv_laser_R,servo_las_closed_R);
        end
        state = PRE_STIM;
    end

end

training_end = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
training_duration = training_end - time_imag_start;
disp(['training duration: ' datestr(training_duration,'HH:MM:SS.FFF')]);

post_note = input(["Anything special after the experiment? \n:"]);
save(['laser_test_os' num2str(mouse_id) '_' datestr(now,'dd-mm-yyyy_HH-MM') '.mat'], ...
    't_stims', 't_port_move', 'trial_order', ...
    'laser_stim_seq', 'water_seq',  'post_note', ...
    'left_lick_times', 'right_lick_times', ...
    'time_imag_start');
writePosition(serv_water,port_near);

