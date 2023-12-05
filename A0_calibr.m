% For the dual lick working memory experiment
% 1st stage of training
% After licking any port, go cue sounds and water is provided
% In case there is an erroneaus restart, save all the variables
warning('off', 'raspi:utils:SaveNotSupported')
save(['D:\dual_lick\backup\' datestr(now,'yyyy-mm-dd-_HH_MM_SS') '.mat']);
%% Clear and close all
close all; clear all; format compact;

%% Important parameters to set up

n_trials = 200; 
t_inbtw = 0.1; t_rasp_pulse = 0.05;
t_estim = n_trials * (t_rasp_pulse + t_inbtw);




%% Set up raspberry pi
rasp_init;

%% Start the calibration
left_good = false; right_good = false; 

while ~ ( left_good && right_good )
    if ~left_good
        
        disp(['calibrating the left valve, estimated time: ' num2str(round(t_estim)) ' seconds'])
        tic
        for n = 1:n_trials
            send_rasp_pulse(mypi, pin_valv_left,2);
            pause(t_inbtw);
        end
        toc
        bottle_weight = input("Weight of the bottle? \n:");
        if bottle_weight == 0
            left_good = true;
        end
    end
    
end


