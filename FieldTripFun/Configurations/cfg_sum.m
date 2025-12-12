function cfg = cfg_sum()
% CFG_SUM Default parameters to use the `ft_plotsummarystats()` function.
    
    cfg = struct();
    cfg.outlier_sd = 3;               % SD threshold for outlier detection
    cfg.layout = [2, 5];              % Grid dimensions [rows, columns]
    cfg.figsize = [650, 500];        % Figure size [width, height] in pixels
    cfg.outermargin = [0.02, 0.02, 0.96, 0.96]; % Outer margins [left, bottom, width, height]
    cfg.channel = 'all';              % Channels to plot ('all' or cell array of labels)
    cfg.datatype = 'time';            % Data type ('time' for data.trial, 'freq' for data.fft)

end