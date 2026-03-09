function ft_plotERP(cfg, data1, data2)
% FT_PLOTERP Custom FieldTrip-style function to plot ERPs for two stimuli.
%
% This function follows the FieldTrip framework, using a cfg structure for
% configuration. It takes two timelock data structures (e.g., from
% ft_timelockanalysis with cfg.keeptrials = 'yes') as input and generates a
% single figure with three subplots:
%   - Top left: Overlaid individual trials + average for stimulus 1.
%   - Top right: Overlaid individual trials + average for stimulus 2.
%   - Bottom: Averages of both stimuli + their difference.
%
% The data structures should have fields like 'trial' (rpt_chan_time dimord),
% 'time', 'label', etc. The function assumes the two data structures have
% compatible time axes and channel labels.
%
% Configuration options (via cfg):
%   cfg.channel: String specifying the channel (e.g., 'Fz'). If empty or
%     not provided, computes a grand average across all channels.
%   cfg.stim1_name: String for stimulus 1 name (default: 'Stimulus 1').
%   cfg.stim2_name: String for stimulus 2 name (default: 'Stimulus 2').
%   cfg.title: Optional main figure title (default: none).
%   cfg.line_color_trials: RGB triplet for individual trial lines (default: [0.8 0.8 0.8], light gray).
%   cfg.line_color_avg: RGB triplet for average lines in top plots (default: [0 0 0], black).
%   cfg.line_color_diff: RGB triplet for difference line (default: [0 1 0], green).
%   cfg.line_width_avg: Line width for averages (default: 2).
%   cfg.show_trial_count: Logical to show trial count in top plots (default: true).
%   cfg.xlim: 1x2 vector for x-axis limits (default: full time range).
%   cfg.ylim: 1x2 vector for y-axis limits (default: auto).
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% Example usage:
%   cfg = [];
%   cfg.channel = 'Fz';
%   cfg.stim1_name = 'Tones Standard';
%   cfg.stim2_name = 'Tones Deviant';
%   ft_plotERP(cfg, timelockTONES_stnd, timelockTONES_dev);

% Set default configuration values
if ~isfield(cfg, 'channel') || isempty(cfg.channel)
    cfg.channel = [];  % Flag for grand average
end
if ~isfield(cfg, 'stim1_name')
    cfg.stim1_name = 'Stimulus 1';
end
if ~isfield(cfg, 'stim2_name')
    cfg.stim2_name = 'Stimulus 2';
end
if ~isfield(cfg, 'line_color_trials')
    cfg.line_color_trials = [0.8 0.8 0.8];
end
if ~isfield(cfg, 'line_color_avg')
    cfg.line_color_avg = [0 0 0];
end
if ~isfield(cfg, 'line_color_diff')
    cfg.line_color_diff = [0 1 0];
end
if ~isfield(cfg, 'line_width_avg')
    cfg.line_width_avg = 2;
end
if ~isfield(cfg, 'show_trial_count')
    cfg.show_trial_count = true;
end
if ~isfield(cfg, 'xlim')
    cfg.xlim = [min(data1.time) max(data1.time)];
end
if ~isfield(cfg, 'ylim')
    cfg.ylim = [];  % Auto
end

visibleplots = 'yes';
saveplots    = 'no';
main = 'no';

% Overrite configuration if saveplot field (structure) specified
if isfield(cfg, 'saveplots')
    visibleplots = cfg.saveplots.visibleplots;
    saveplots    = cfg.saveplots.saveplots;
    main         = cfg.saveplots.main;
    skip         = cfg.saveplots.skip;
    plotfolder   = cfg.saveplots.plotfolder;
end

% Specify whether the plot is visible or not
if strcmp(visibleplots, 'yes'); Show = 'on'; else; Show = 'off'; end

% Validate input data
if ~isfield(data1, 'trial') || ~isfield(data2, 'trial')
    error('Input data must have ''trial'' field (use ft_timelockanalysis with keeptrials=''yes'').');
end
if ~strcmp(data1.dimord, 'rpt_chan_time') || ~strcmp(data2.dimord, 'rpt_chan_time')
    error('Dimord must be ''rpt_chan_time''.');
end
if ~isequal(data1.time, data2.time)
    error('Time axes must match between data1 and data2.');
end
if ~isequal(data1.label, data2.label)
    error('Channel labels must match between data1 and data2.');
end

% Extract time axis
time = data1.time;

% Extract or compute data for plotting
if isempty(cfg.channel)
    % Grand average over channels
    trials1 = squeeze(mean(data1.trial, 2));  % [nTrials1 x nTimes]
    avg1 = mean(trials1, 1);  % [1 x nTimes]
    
    trials2 = squeeze(mean(data2.trial, 2));  % [nTrials2 x nTimes]
    avg2 = mean(trials2, 1);  % [1 x nTimes]
    
    chan_label = 'Grand Average';
else
    % Specific channel
    chan_idx = find(strcmp(data1.label, cfg.channel));
    if isempty(chan_idx)
        error('Specified channel ''%s'' not found in data.', cfg.channel);
    end
    
    trials1 = squeeze(data1.trial(:, chan_idx, :));  % [nTrials1 x nTimes]
    avg1 = mean(trials1, 1);  % [1 x nTimes]
    
    trials2 = squeeze(data2.trial(:, chan_idx, :));  % [nTrials2 x nTimes]
    avg2 = mean(trials2, 1);  % [1 x nTimes]
    
    chan_label = cfg.channel;
end

% Compute difference
diff_avg = avg1 - avg2;

% Create figure
fig = figure('Visible', Show, 'Name', 'Custom ERP Plot', 'NumberTitle', 'off');
if isfield(cfg, 'title')
    sgtitle(cfg.title);
end

% Top left: Stimulus 1 trials + average
subplot(2, 2, 1);
hold on;
plot(time, trials1', 'Color', cfg.line_color_trials, 'LineWidth', 0.5);
plot(time, avg1, 'Color', cfg.line_color_avg, 'LineWidth', cfg.line_width_avg);
title(sprintf('%s at %s', cfg.stim1_name, chan_label));
xlabel('Time (s)');
ylabel('Amplitude');
xlim(cfg.xlim);
if ~isempty(cfg.ylim)
    ylim(cfg.ylim);
end
if cfg.show_trial_count
    text(0.05, 0.95, sprintf('N = %d', size(trials1, 1)), 'Units', 'normalized', 'VerticalAlignment', 'top');
end
grid on;
hold off;

% Top right: Stimulus 2 trials + average
subplot(2, 2, 2);
hold on;
plot(time, trials2', 'Color', cfg.line_color_trials, 'LineWidth', 0.5);
plot(time, avg2, 'Color', cfg.line_color_avg, 'LineWidth', cfg.line_width_avg);
title(sprintf('%s at %s', cfg.stim2_name, chan_label));
xlabel('Time (s)');
ylabel('Amplitude');
xlim(cfg.xlim);
if ~isempty(cfg.ylim)
    ylim(cfg.ylim);
end
if cfg.show_trial_count
    text(0.05, 0.95, sprintf('N = %d', size(trials2, 1)), 'Units', 'normalized', 'VerticalAlignment', 'top');
end
grid on;
hold off;

% Bottom: Averages + difference
subplot(2, 2, 3:4);
hold on;
plot(time, avg1, 'Color', [0 0 1], 'LineWidth', cfg.line_width_avg, 'DisplayName', cfg.stim1_name);  % Blue
plot(time, avg2, 'Color', [1 0 0], 'LineWidth', cfg.line_width_avg, 'DisplayName', cfg.stim2_name);  % Red
plot(time, diff_avg, 'Color', cfg.line_color_diff, 'LineWidth', cfg.line_width_avg, 'DisplayName', 'Difference');
title('Averages and Difference');
xlabel('Time (s)');
ylabel('Amplitude');
xlim(cfg.xlim);
if ~isempty(cfg.ylim)
    ylim(cfg.ylim);
end
legend('Location', 'best');
grid on;
hold off;

% If plots are to be saved then save them
if strcmp(saveplots, 'yes')
    cfg_sp = [];
    cfg_sp.fig = fig;
    cfg_sp.plotname = 'plotERP';
    cfg_sp.main = main;
    cfg_sp.skip = skip;
    cfg_sp.plotfolder = plotfolder;
    savehandlefig(cfg_sp)
    pause(.02);
end

end