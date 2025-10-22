function ft_plotsummarystats(cfg, data)
% FT_PLOTSUMMARYSTATS Plot summary statistics and outliers for EEG data
%
% Usage:
%   ft_plotsummarystats(cfg, data)
%
% Input:
%   cfg.outlier_sd       = SD threshold for outlier detection (default: 3)
%   cfg.layout           = Grid dimensions [rows, columns] (default: [2, 5])
%   cfg.figsize          = Figure size [width, height] in pixels (default: [1000, 600])
%   cfg.outermargin      = Outer margins [left, bottom, width, height] (default: [0.02, 0.02, 0.96, 0.96])
%   cfg.channel          = Channels to plot ('all' or cell array, default: 'all')
%   cfg.datatype         = Data type ('time' for data.trial, 'freq' for data.fft, default: 'time')
%   data                 = FieldTrip raw data structure with fields data.trial or data.fft, data.label
%
% Output:
%   None (creates a figure)

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'channel', 'datatype'});
cfg = ft_checkconfig(cfg, 'forbidden', {});
if ~isfield(data, 'label') || (~isfield(data, 'trial') && ~isfield(data, 'fft'))
    ft_error('Input data must have fields data.label and either data.trial or data.fft');
end
if strcmp(cfg.datatype, 'time') && ~isfield(data, 'trial')
    ft_error('data.trial required for cfg.datatype=''time''');
elseif strcmp(cfg.datatype, 'freq') && ~isfield(data, 'fft')
    ft_error('data.fft required for cfg.datatype=''freq''');
end

% Set defaults
cfg.outlier_sd = ft_getopt(cfg, 'outlier_sd', 3);
cfg.layout = ft_getopt(cfg, 'layout', [2, 5]);
cfg.figsize = ft_getopt(cfg, 'figsize', [1000, 600]);
cfg.outermargin = ft_getopt(cfg, 'outermargin', [0.02, 0.02, 0.96, 0.96]);
cfg.channel = ft_getopt(cfg, 'channel', 'all');
cfg.datatype = ft_getopt(cfg, 'datatype', 'time');

% Select channels
if strcmp(cfg.channel, 'all')
    chanidx = 1:length(data.label);
else
    chanidx = ft_channelselection(cfg.channel, data.label);
end
nchan = length(chanidx);

% Select data based on datatype
if strcmp(cfg.datatype, 'time')
    dat = cat(3, data.trial{:}); % nchan x nsamples x ntrials
elseif strcmp(cfg.datatype, 'freq')
    dat = cat(3, data.fft{:}); % nchan x nfreq x ntrials
end
dat = dat(chanidx, :, :); % Select channels
ntrials = size(dat, 3);

% Compute statistics
dat_reshaped = reshape(dat, nchan, []); % Channels x (samples * trials)
chan_mean = mean(dat_reshaped, 2); % nchan x 1
chan_var = var(dat_reshaped, 0, 2); % nchan x 1

dat_per_trial = reshape(dat, nchan, [], ntrials); % Channels x samples x trials
dat_per_trial = squeeze(mean(dat_per_trial, 1)); % samples x trials
trial_mean = mean(dat_per_trial, 1); % 1 x ntrials
trial_var = var(dat_per_trial, 0, 1); % 1 x ntrials

% Compute Z-scores
chan_var_z = zscore(chan_var);
trial_var_z = zscore(trial_var);

% Compute MAD scores
chan_med_mad = mad(chan_var, 1);
chan_mad = (chan_var - median(chan_var)) / chan_med_mad;
trial_med_mad = mad(trial_var, 1);
trial_mad = (trial_var - median(trial_var)) / trial_med_mad;

% Identify outliers
outlier_chan_z = find(abs(chan_var_z) > cfg.outlier_sd);
outlier_chan_mad = find(abs(chan_mad) > cfg.outlier_sd * 1.4826);
outlier_trial_z = find(abs(trial_var_z) > cfg.outlier_sd);
outlier_trial_mad = find(abs(trial_mad) > cfg.outlier_sd * 1.4826);

% Create figure and tiled layout
figure('Position', [100, 100, cfg.figsize(1), cfg.figsize(2)], 'Color', 'white');
t = tiledlayout(cfg.layout(1), cfg.layout(2), 'TileSpacing', 'compact', 'Padding', 'tight');

% Add main title
if strcmp(cfg.datatype, 'time')
    title_str = 'Channel and Trial {Time-Domain} Amplitude Summary Statistics';
else
    title_str = 'Channel and Trial {Frequency-Domain} Amplitude Summary Statistics';
end
title(t, title_str, 'FontSize', 14, 'FontWeight', 'bold');

% Channel plots
nexttile; histogram(chan_mean); title('Channel Mean');
nexttile; plot(chan_mean, '.', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b'); title('Channel Mean');
nexttile; histogram(chan_var); title('Channel Variance');
nexttile;
hold on;
plot(chan_var_z, '.', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
plot(outlier_chan_z, chan_var_z(outlier_chan_z), 'or', 'MarkerSize', 12, 'LineWidth', 1.5);
for i = 1:length(outlier_chan_z)
    text(outlier_chan_z(i), chan_var_z(outlier_chan_z(i)) - 0.55, data.label{chanidx(outlier_chan_z(i))}, ...
         'FontSize', 8, 'Color', 'r');
end
hold off;
title('Channel Variance (Z-scores)');

nexttile;
hold on;
plot(chan_mad, '.', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
plot(outlier_chan_mad, chan_mad(outlier_chan_mad), 'or', 'MarkerSize', 12, 'LineWidth', 1.5);
for i = 1:length(outlier_chan_mad)
    text(outlier_chan_mad(i), chan_mad(outlier_chan_mad(i)) - 0.55, data.label{chanidx(outlier_chan_mad(i))}, ...
         'FontSize', 8, 'Color', 'r');
end
hold off;
title('Channel Variance (MAD)');

% Trial plots
nexttile; histogram(trial_mean); title('Trial Mean');
nexttile; plot(trial_mean, '.', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b'); title('Trial Mean');
nexttile; histogram(trial_var); title('Trial Variance');
nexttile;
hold on;
plot(trial_var_z, '.', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
plot(outlier_trial_z, trial_var_z(outlier_trial_z), 'or', 'MarkerSize', 12, 'LineWidth', 1.5);
for i = 1:length(outlier_trial_z)
    text(outlier_trial_z(i), trial_var_z(outlier_trial_z(i)) - 0.35, num2str(outlier_trial_z(i)), ...
         'FontSize', 8, 'Color', 'r');
end
hold off;
title('Trial Variance (Z-scores)');

nexttile;
hold on;
plot(trial_mad, '.', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'b');
plot(outlier_trial_mad, trial_mad(outlier_trial_mad), 'or', 'MarkerSize', 12, 'LineWidth', 1.5);
for i = 1:length(outlier_trial_mad)
    text(outlier_trial_mad(i), trial_mad(outlier_trial_mad(i)) - 0.55, num2str(outlier_trial_mad(i)), ...
         'FontSize', 8, 'Color', 'r');
end
hold off;
title('Trial Variance (MAD)');

% Set outer margins
t.OuterPosition = cfg.outermargin;
end