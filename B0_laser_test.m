%% Laser test

close all; % clear variables; format compact;

% Initialize Raspberry Pi
rasp_init;

for i=1:3
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