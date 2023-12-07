%% Easy way to view m y tifs with Ca
% imaging

% processing stages: reg, post-reg, frame_all, frame_allt

%% Load the files
clear variables;
tibor = true; 
if tibor
    [file_reg, path_name] =  uigetfile("Choose file ending with _reg_post");
    cd(path_name);

    file_tif = uigetfile('*.tif', "Choose original tif file");
    file_processed = [file_tif(1:end-4) '_data_processed.mat'];

else
    mouse_id  = 65;
    exp_type = 'ambig';
    process_stage = 'reg'; 'frame_all';
    path_name = [ 'D:\CaIm\' exp_type '\os'  num2str(mouse_id) '\' ];
    file_tif = [path_name 'os' num2str(mouse_id) '_' exp_type ' - 1.tif'];
end



istif = true;


load([path_name, file_reg]); load([path_name file_processed]);

% load([path_name 'os' num2str(mouse_id) '_' exp_type '_data_processed.mat'], 'roifn');

neu_data=reg;

%% Prep the figures
h = figure(); hold on;
% subplot(1,2,1); 
% Creating a figure
set(h,'name','figure_name','numbertitle','on') % Setting the name of the figure
% clf(h) % Erase the contents of the figure
set(h,'WindowStyle','normal') % Insert the figure to dock

% screens = get(groot, 'MonitorPositions');
% numMonitors = size(screens, 1);
% 
% % Specify the monitor index for the second screen
% monitorIndex = 2;
% 
% % Set the figure position to the second screen
% figurePosition = screens(monitorIndex, :);
% set(h, 'Position', [figurePosition(1) -700 1200 1200 ]);
% 
% % Optional: Maximize the figure window on the second screen
% % set(gcf, 'WindowState', 'maximized');
% 
% % % make a 2nd figure if tif is 
% % if istif
% %     tiffig = figure(4); hold on;
% %     % Creating a figure
%     set(tiffig,'name','figure_name','numbertitle','on') % Setting the name of the figure
%     % clf(h) % Erase the contents of the figure
%     set(tiffig,'WindowStyle','normal') % Insert the figure to dock
% 
% 
%     % Set the figure position to the second screen
%     figurePosition = screens(monitorIndex, :);
%     set(tiffig, 'Position', [figurePosition(1) 600 1000 600 ]);
% end

%% Plot the image
% imshow(imaxy, 'InitialMagnification', 800);
speed = 100;
neu_rows = zeros(size(seedsfn,1));
neu_cols = zeros(size(seedsfn,1));
res = size(reg);
for neu = 1:size(seedsfn,1)
    
    [neu_rows(neu), neu_cols(neu)] = ind2sub([res(1),res(2)], seedsfn(neu));
   % plot(row, col, 'o', 'MarkerEdgeColor', [1 0 0], 'MarkerFaceColor', 'none', 'MarkerSize', 11);
    

end
istif = true;

for fn = 1:speed:size(neu_data,3)
        % d
        if istif
            %figure(tiffig);
            subplot(1,2,1);
            neu_datta = imread(file_tif, 'Index', fn);
            imshow(neu_datta, [], 'InitialMagnification', 1000); colormap(gray); hold on;
        % imshow(neu_data(:,:,fn), 'InitialMagnification', 1000); hold on;
       plot(neu_cols,neu_rows, 'ro', 'MarkerFaceColor', 'none', 'MarkerSize', 6);
        end

        subplot(1,2,2);
        imshow(neu_data(:,:,fn), 'InitialMagnification', 1000); hold on;
        plot(neu_cols,neu_rows, 'ro', 'MarkerFaceColor', 'none', 'MarkerSize', 6);
        pause(0.05)

    
% else
%     for fn = 1:speed:size(neu_data,3)
% 
% 
%         % imshow(neu_data(:,:,fn), 'InitialMagnification', 1000); hold on;
%        % plot(neu_cols,neu_rows, 'ro', 'MarkerFaceColor', 'none', 'MarkerSize', 11);
%         pause(0.01)
% 
%     end
end
