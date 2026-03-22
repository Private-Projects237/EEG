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
%
%   cfg.returnfft        = Will return fft related information (default:no)
%   cfg.returnfftchanavg  = Will return the average of fft per chan plus frequency bands (default: 'no')
%   cfg.deltarange       = Specify the band for delta (default: [0.5 4])
%   cfg.thetarange       = Specify the band for theta (default: [4 8])
%   cfg.alpharange       = Specify the band for alpha (default: [8 12])
%   cfg.betarange        = Specify the band for beta (default: [13 30])
%   
%   data                 = FieldTrip raw data structure with fields data.trial, data.time, data.label, data.fsample
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% Output:
%   data.fft             = Matrices of amplitude spectra for each trial in data
%   data.avgfft         = A vector of average amplitude spectra for each channel
%   data.avgdelta       = A vector of average delta for each channel
%   data.avgtheta       = A vector of average theta for each channel
%   data.avgalpha       = A vector of average alpha for each channel
%   data.avgbeta        = A vector of average beta for each channel
%   (creates a figure)
%
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
cfg.returnfft = ft_getopt(cfg, 'returnfft', 'no');
cfg.returnfftchanavg = ft_getopt(cfg, 'returnfftchanavg', 'no');
cfg.deltarange = ft_getopt(cfg, 'deltarange', [0.5 4]);
cfg.thetarange = ft_getopt(cfg, 'thetarange', [4 8]);
cfg.alpharange = ft_getopt(cfg, 'alpharange', [8 12]);
cfg.betarange = ft_getopt(cfg, 'betarange', [13 30]);

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
fft_dat_cell = cell(1, ntrials);

% Compute FFT for each trial
for trl = 1:ntrials
    signal = data.trial{trl}(chanidx, :); % Select channels
    fft_chan = fft(signal, [], 2) / nsamples; % Normalized FFT
    fft_magnitude = abs(fft_chan(:, 1:nfreq)); % Positive frequencies (amplitude)
    fft_magnitude(:, 2:end-1) = 2 * fft_magnitude(:, 2:end-1); % Double non-DC/nyquist amplitudes
    fft_dat(:, :, trl) = fft_magnitude;
    fft_dat_cell{trl} = fft_magnitude;
end

% Calculate averages for fft (for each channel)
avgfft = mean(fft_dat, 3); % nchan x nfreq

% Index the frequencies to get the bands of interest
delta_idx  = freq_axis >= cfg.deltarange(1)  & freq_axis <= cfg.deltarange(2);
theta_idx  = freq_axis >= cfg.thetarange(1)  & freq_axis <= cfg.thetarange(2);
alpha_idx  = freq_axis >= cfg.alpharange(1)  & freq_axis <= cfg.alpharange(2);
beta_idx   = freq_axis >= cfg.betarange(1)   & freq_axis <= cfg.betarange(2);

% Average amplitude within each band (across trials and frequency bins)
avgdelta = squeeze(mean(mean(fft_dat(:, delta_idx, :), 2), 3)); % nchan x 1
avgtheta = squeeze(mean(mean(fft_dat(:, theta_idx, :), 2), 3));
avgalpha = squeeze(mean(mean(fft_dat(:, alpha_idx, :), 2), 3));
avgbeta  = squeeze(mean(mean(fft_dat(:, beta_idx , :), 2), 3));

% Return requested data
if strcmp(cfg.returnfft, 'yes')
    data.fft = fft_dat_cell;           % cell array, each entry nchan x nfreq
end
if strcmp(cfg.returnfftchanavg, 'yes')
    data.dimord = 'chan'; % needed for topo plots
    data.avgfft   = mean(avgfft, 2); % Row means          
    data.avgdelta = avgdelta;
    data.avgtheta = avgtheta;
    data.avgalpha = avgalpha;
    data.avgbeta  = avgbeta;
end

% Create figure and tiled layout
fig = figure('Visible', Show, 'Position', [100, 100, cfg.figsize(1), cfg.figsize(2)], 'Color', 'white');
t = tiledlayout(cfg.layout(1), cfg.layout(2), 'TileSpacing', 'compact', 'Padding', 'compact');

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
    axis tight;
    set(gca, 'XLim', cfg.freqrange);
    title(data.label{chanidx(chan)}, 'FontSize', cfg.chantitlefontsize);
end

% Add axis labels
xlabel(t, 'Frequency (Hz)', 'FontSize', cfg.labelfontsize);
ylabel(t, 'Amplitude', 'FontSize', cfg.labelfontsize);

% Set outer margins
t.OuterPosition = cfg.outermargin;

% If plots are to be saved then save them
if strcmp(saveplots, 'yes')
    cfg_sp = [];
    cfg_sp.fig = fig;
    cfg_sp.plotname = 'trialchanfft';
    cfg_sp.main = main;
    cfg_sp.skip = skip;
    cfg_sp.plotfolder = plotfolder;
    savehandlefig(cfg_sp)
end 

end