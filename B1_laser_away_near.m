
% In case there is an erroneaus restart, save all the variables
warning('off', 'raspi:utils:SaveNotSupported')
save(['D:\dual_lick\backup\' datestr(now,'yyyy-mm-dd-_HH_MM_SS') '.mat']);

clear variables; 
close all;
mouse_id = input('Mouse id\n:'); 

training_type = 'B1';

%% Set up raspberry pi

rasp_init;
%% idk how to name this
laser_stim_sec = 1;

laser_stim_param = [7,43,6,30];

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
lick_n_L = 0;
lick_n_R= 0;

%% States
PRE_STIM = 1;
PORT_MOVE = 2;
INBTW_STIM_PORT = 3;
STIM_LASER = 4;
STIM_LASER_WAIT = 5;
state = PRE_STIM;
inbtw_range = [2500, 3500];
pre_range = [1000 1500];
pre_period  = randi(pre_range);
inbtw_period = randi(inbtw_range);
laser_dur = 1150;

%% Trial order;
tr_per_cond = 40; n_cond = 6; tr_total = tr_per_cond * n_cond;
rng(1);
blocks_away = randi([8,9],1,ceil(tr_per_cond/4)); blocks_near = randi([12,21],1,ceil(tr_per_cond/4)); 
% sum(blocks_near), sum(blocks_away)
blocks_away(end) = blocks_away(end)  - 2;
blocks_near(end) =  blocks_near(end) + 3;

blocks_near_water_seq = [ ones(1, tr_per_cond*2) 2*ones(1, tr_per_cond*2)];
blocks_away_laser_seq = [ zeros(1, tr_per_cond) ones(1, tr_per_cond)];
blocks_near_laser_seq = [ zeros(1, tr_per_cond) ones(1, tr_per_cond) ...
                          zeros(1, tr_per_cond) ones(1, tr_per_cond)];

blocks_near_order = randperm(tr_per_cond*4);
blocks_near_water_seq = blocks_near_water_seq(blocks_near_order);
blocks_near_laser_seq = blocks_near_laser_seq(blocks_near_order);

blocks_away_order = randperm(tr_per_cond*2);
blocks_away_laser_seq = blocks_away_laser_seq(blocks_away_order);

laser_stim_seq = [];
water_seq = [];
n_away = 1; n_near = 1;
for n = 1:length(blocks_near)
    % The near block
    
    block_near_water = blocks_near_water_seq(n_near:n_near+blocks_near(n)-1);
    block_near_laser = blocks_near_laser_seq(n_near:n_near+blocks_near(n)-1);
    block_away_water = zeros(1,blocks_away(n));
    block_away_laser = blocks_away_laser_seq(n_away:n_away+blocks_away(n)-1);
    

    water_seq = [water_seq block_near_water block_away_water];

    laser_stim_seq = [laser_stim_seq block_near_laser block_away_laser];

    n_near = n_near + blocks_near(n);
    n_away = n_away + blocks_away(n);
end


curr_tr = 1;


%% Start imaging

time_stim_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
time_imag_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');

send_rasp_pulse(mypi, pin_ca_imaging, 500);

training_start = time_imag_start;

%% Running the trials
t_stims = zeros(1, tr_per_cond*n_cond);
t_port_move = zeros(1, tr_per_cond*n_cond);

time_pre_start = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
t_port_move(curr_tr) = milliseconds(time_pre_start-time_imag_start);
%     if curr_tr>2 && (water_seq(curr_tr) >= 1) && (water_seq(curr_tr-1)==0)
%         move(y_motor, -2000); % negative moves closer
%     elseif curr_tr>2 && (water_seq(curr_tr) == 0) && (water_seq(curr_tr-1)>=1)
%         move(y_motor, 2000); % positive moves away
%     end

% HOW IT WAS WITH SERVO
%     if water_seq(curr_tr) == 1
%         writePosition(servo_water,port_near);
%     else
%         writePosition(servo_water,port_away);
%     end

    if laser_stim_seq(curr_tr) == 1
        writePosition(servo_las_L,servo_las_open_L);
        writePosition(servo_las_R,servo_las_open_R);
    else
        writePosition(servo_las_L,servo_las_closed_L);
        writePosition(servo_las_R,servo_las_closed_R);
    end


while curr_tr <= tr_per_cond * n_cond 

    % Detect licks
    scr_detect_lick;

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
        disp(['trial ' num2str(curr_tr) ', water ' num2str(water_seq(curr_tr)) ...
               ', laser ' num2str(laser_stim_seq(curr_tr))])
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
            if water_seq(curr_tr) == 2
                if randi([0,1])
                    send_rasp_pulse(mypi, pin_valv_right, 5); pause(0.05);
                    send_rasp_pulse(mypi, pin_valv_left, 5); pause(0.05);
                else
                    send_rasp_pulse(mypi, pin_valv_left , 5); pause(0.05);
                    send_rasp_pulse(mypi, pin_valv_right, 5); pause(0.05);
                end

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
        if curr_tr>2 && (water_seq(curr_tr) >= 1) && (water_seq(curr_tr-1)==0)
            move(y_motor, -y_move); % negative moves closer
        elseif curr_tr>2 && (water_seq(curr_tr) == 0) && (water_seq(curr_tr-1)>=1)
            move(y_motor, y_move); % positive moves away
        end


%         if water_seq(curr_tr) == 0
%             writePosition(servo_water,port_away);
%         else
%             writePosition(servo_water,port_near);
%         end
        if laser_stim_seq(curr_tr) == 1
            writePosition(servo_las_L,servo_las_open_L);
            writePosition(servo_las_R,servo_las_open_R);
        else
            writePosition(servo_las_L,servo_las_closed_L);
            writePosition(servo_las_R,servo_las_closed_R);
        end
        state = PRE_STIM;
    end

end

training_end = datetime (datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
                'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
training_duration = training_end - time_imag_start;
disp(['experiment duration: ' datestr(training_duration,'HH:MM:SS.FFF')]);

post_note = input(["Anything special after the experiment? \n:"], "s");



save_behav_all;
release(y_motor);
writePosition(servo_water,port_near);

