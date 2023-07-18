% calibrating valves
function done = give_freebies(n_free, t_btw, mypi)


    % t_btw =2.8;
    
    
    % The pics for valves
    pin_valve_l = 18; % 
    pin_valve_r = 15; % 
    
    % Initialize rasp
    % mypi = raspi();
    
    %configurePin(mypi,pin_valve_r,'DigitalOutput');
    
    % Let's go test!
    disp(['giving ' num2str(n_free) ' freebies']);
    for i = 1:n_free
    
        writeDigitalPin(mypi,pin_valve_r,1);
        pause(.007);
        writeDigitalPin(mypi,pin_valve_r,0);
        
    
        pause(t_btw);
    
        writeDigitalPin(mypi,pin_valve_l,1);
        pause(.007);
        writeDigitalPin(mypi,pin_valve_l,0);
        
        pause(t_btw);
    end
    done=1;
end