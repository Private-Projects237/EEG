function cfg = cfg_view()
% CFG_VIEW Default parameters to use the `ft_databrowser()` function.

    cfg = [];
    cfg.continuous = 'yes'; % Combine trials
    cfg.channel = 'all';  
    cfg.layout = 'EEG1005.lay'; %'easycapM1.mat';
    cfg.viewmode = 'vertical';
    cfg.blocksize = 5; % seconds
    cfg.ylim = [-60, 60]; % Set y-axis limits 
    cfg.artifactalpha = 0.8;
    cfg.position = [100, 100, 1200, 800];  % [left, bottom, width, height] in pixels

end