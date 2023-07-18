% Script for detecting licks to be used within the behavioral program for
% dual lick training
% Required variables in the main script: 


for i=2:sens_buffer_len
    sens_buffer_left(i-1) = sens_buffer_left(i);
end

sens_buffer_left(sens_buffer_len) = sens_before_left;
sens_now_left = readDigitalPin(mypi,pin_sens_left);
if (sum(sens_buffer_left) == 0) && (sens_now_left == 1)
    lick_detected_left = 1;
    left_lick_time = datetime(datestr(now,'dd-mm-yyyy_HH:MM:SS.FFF'), ...
            'InputFormat','dd-MM-yyyy_HH:mm:ss.SSS');
    lick_n_L = lick_n_L +1;
    left_lick_times(lick_n_L) = milliseconds(left_lick_time-training_start);
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
    lick_n_R = lick_n_R +1;
    right_lick_times(lick_n_R) = milliseconds(right_lick_time-training_start);
else
    lick_detected_right = 0;
end
sens_before_right = sens_now_right;

