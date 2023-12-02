% send short pulse from raspberry pi
function [] = send_rasp_pulse(mypi, pin, pulse_dur_ms) 
    writeDigitalPin(mypi,pin,1);
    pause(pulse_dur_ms*0.01);
    writeDigitalPin(mypi,pin,0);
end