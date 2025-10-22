function [data] = ft_plotchannelfft(cfg, data)
% FT_PLOTCHANNELFFT Plot channel-wise power spectra for EEG data
%
% Usage:
%   ft_plotchannelfft(cfg, data)
%
% Input:
%   cfg.channel           = Channels to plot ('all' or cell array, default: 'all')
%   cfg.layout           = Grid dimensions [rows, columns] (default: automatic)
%   cfg.figsize          = Figure size [width, height] in pixels (default: [1200, 800])
%   cfg.plotindividual   = Plot individual trial spectra ('yes', 'no', default: 'yes')
%   cfg.plotmean         = Plot mean spectrum across trials ('yes', 'no', default: 'yes')
%   cfg.titlefontsize    = Font size for main title (default: 14)
%   cfg.chantitlefontsize = Font size for channel titles (default: 10)
%   cfg.labelfontsize    = Font size for axis labels (default: 12)
%   cfg.outermargin      = Outer margins [left, bottom, width, height] (default: [0.02, 0.02, 0.96, 0.96])
%   cfg.freqrange        = Frequency range for x-axis [min, max] in Hz (default: [1, 50])
%   data                 = FieldTrip raw data structure with fields data.trial, data.time, data.label, data.fsample
%
% Output:
%   data (includes data.fft)

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'channel'});
cfg = ft_checkconfig(cfg, 'forbidden', {});
if ~isfield(data, 'trial') || ~isfield(data, 'time') || ~isfield(data, 'label') || ~isfield(data, 'fsample')
    ft_error('Input data must have fields data.trial, data.time, data.label, and data.fsample');
end

% Set defaults
cfg.channel = ft_getopt(cfg, 'channel', 'all');
cfg.figsize = ft_getopt(cfg, 'figsize', [1200, 800]);
cfg.plotindividual = ft_getopt(cfg, 'plotindividual', 'yes');
cfg.plotmean = ft_getopt(cfg, 'plotmean', 'yes');
cfg.titlefontsize = ft_getopt(cfg, 'titlefontsize', 14);
cfg.chantitlefontsize = ft_getopt(cfg, 'chantitlefontsize', 10);
cfg.labelfontsize = ft_getopt(cfg, 'labelfontsize', 12);
cfg.outermargin = ft_getopt(cfg, 'outermargin', [0.02, 0.02, 0.96, 0.96]);
cfg.freqrange = ft_getopt(cfg, 'freqrange', [1, 50]);

% Select channels
if strcmp(cfg.channel, 'all')
    chanidx = 1:length(data.label);
else
    chanidx = ft_channelselection(cfg.channel, data.label);
end
nchan = length(chanidx);

% Determine layout if not specified
if ~isfield(cfg, 'layout') || isempty(cfg.layout)
    cfg.layout = [ceil(sqrt(nchan)), ceil(nchan/ceil(sqrt(nchan)))];
end

% FFT calculations
fsample = data.fsample;
ntrials = length(data.trial);
nsamples = size(data.trial{1}, 2);
nfreq = floor(nsamples/2) + 1; % Number of positive frequency bins
freq_axis = (0:nfreq-1) * fsample / nsamples; % Frequency axis

% Initialize FFT storage
fft_dat = zeros(nchan, nfreq, ntrials);
data.fft = cell(1, ntrials);

% Compute FFT for each trial
for trl = 1:ntrials
    signal = data.trial{trl}(chanidx, :); % Select channels
    fft_chan = fft(signal, [], 2) / nsamples; % Normalized FFT
    fft_magnitude = abs(fft_chan(:, 1:nfreq)); % Positive frequencies
    fft_magnitude(:, 2:end-1) = 2 * fft_magnitude(:, 2:end-1); % Double non-DC/nyquist amplitudes
    fft_dat(:, :, trl) = fft_magnitude;
    data.fft{trl} = fft_magnitude;
end

% Compute mean across trials
avgfft = mean(fft_dat, 3); % nchan x nfreq

% Create figure and tiled layout
figure('Position', [100, 100, cfg.figsize(1), cfg.figsize(2)], 'Color', 'white');
t = tiledlayout(cfg.layout(1), cfg.layout(2), 'TileSpacing', 'compact', 'Padding', 'tight');

% Add main title
title(t, 'Average Power Spectra Across Channels', 'FontSize', cfg.titlefontsize, 'FontWeight', 'bold');

% Plot power spectra for each channel
for chan = 1:nchan
    nexttile;
    hold on;
    if strcmp(cfg.plotindividual, 'yes')
        % Plot all trial spectra
        plot(freq_axis, squeeze(fft_dat(chan, :, :))', ...
             'Color', [0.7, 0.7, 0.7], 'LineWidth', 0.5);
    end
    if strcmp(cfg.plotmean, 'yes')
        % Plot mean spectrum
        plot(freq_axis, avgfft(chan, :), ...
             'Color', [0, 0, 0], 'LineWidth', 2);
    end
    hold off;
    
    % Axis settings
    set(gca, 'XTick', [], 'YTick', [], 'Box', 'on');
    axis tight;
    set(gca, 'XLim', cfg.freqrange);
    title(data.label{chanidx(chan)}, 'FontSize', cfg.chantitlefontsize);
end

% Add axis labels
xlabel(t, 'Frequency (Hz)', 'FontSize', cfg.labelfontsize);
ylabel(t, 'Amplitude', 'FontSize', cfg.labelfontsize);

% Set outer margins
t.OuterPosition = cfg.outermargin;
end