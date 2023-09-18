tic
for i = 1:1000
j=readDigitalPin(mypi,pin_sens_left);
p=readDigitalPin(mypi,pin_sens_right);
end
toc

arduinoObj = serialport("COM6",9600, "Timeout",0.1);
configureTerminator(arduinoObj,"CR/LF");
flush(arduinoObj);
pause(1.5);

arduinoObj.UserData = struct("Data",[],"Count",1);
id = 'serialport:serialport:ReadlineWarning';
warning('off',id);

for i = 1:80
    pause(1);

        data = readline(arduinoObj);
        disp(data);
        data = readline(arduinoObj);
        disp(data);


end

clear arduinoObj;

% 
% function readSineWaveData(src, ~)
% 
% % Read the ASCII data from the serialport object.
% data = readline(src);
% 
% % Convert the string data to numeric type and save it in the UserData
% % property of the serialport object.
% src.UserData.Data(end+1) = str2double(data);
% 
% % Update the Count value of the serialport object.
% src.UserData.Count = src.UserData.Count + 1;
% 
% % If 1001 data points have been collected from the Arduino, switch off the
% % callbacks and plot the data.
% if src.UserData.Count > 21
%     configureCallback(src, "off");
%     plot(src.UserData.Data(2:end));
% end
% end


