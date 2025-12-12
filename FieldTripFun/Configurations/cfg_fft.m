function cfg = cfg_fft()
% CFG_FFT Default parameters to use the `ft_plotchannelfft()` function.

    cfg = struct();
    cfg.channel = 'all';              % Channels to plot ('all' or cell array of labels)
    cfg.layout = [8, 4];              % Grid dimensions [rows, columns]
    cfg.figsize = [650, 800];        % Figure size [width, height] in pixels
    cfg.plotindividual = 'yes';       % Plot individual trials ('yes', 'no')
    cfg.plotmean = 'yes';             % Plot mean across trials ('yes', 'no')
    cfg.titlefontsize = 14;           % Font size for main title
    cfg.chantitlefontsize = 10;       % Font size for channel titles
    cfg.labelfontsize = 12;           % Font size for axis labels
    cfg.outermargin = [0.02, 0.02, 0.96, 0.96]; % Outer margins [left, bottom, width, height]
    cfg.freqrange = [1, 60];          % Frequency range for x-axis [min, max] in Hz
    cfg.returnfft = 'yes';             % Will return amplitudes (freq) for each trial
    cfg.returnfftchanavg = 'yes';      % Will return averaged amplites (freq) by channel + FB!

end