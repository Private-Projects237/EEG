function [data] = ft_plotchannelavg(cfg, data)
% FT_PLOTCHANNELAVG Plot channel-wise average and/or individual trial EEG data
%
% Usage:
%   ft_plotchannelavg(cfg, data)
%
% Input:
%   cfg.channel           = Channels to plot ('all' or cell array, default: 'all')
%   cfg.layout            = Grid dimensions [rows, columns] (default: automatic)
%   cfg.figsize           = Figure size [width, height] in pixels (default: [1200, 800])
%   cfg.plotindividual    = Plot individual trials ('yes', 'no', default: 'yes')
%   cfg.plotmean          = Plot mean across trials ('yes', 'no', default: 'yes')
%   cfg.titlefontsize     = Font size for main title (default: 14)
%   cfg.chantitlefontsize = Font size for channel titles (default: 10)
%   cfg.labelfontsize     = Font size for axis labels (default: 12)
%   cfg.outermargin       = Outer margins [left, bottom, width, height] (default: [0.02, 0.02, 0.96, 0.96])
%   cfg.returnchanavg     = = Will return the average amplitude for each channel
%
%   data                  = FieldTrip raw data structure with fields data.trial, data.time, data.label
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% Output:
%    data.avgtime         = A channel vector of mean amplitude activity across trials
%    (creates a figure)
%
% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'channel'});
cfg = ft_checkconfig(cfg, 'forbidden', {});
if ~isfield(data, 'trial') || ~isfield(data, 'time') || ~isfield(data, 'label')
    ft_error('Input data must have fields data.trial, data.time, and data.label');
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
cfg.returnchanavg = ft_getopt(cfg, 'returnchanavg', 'no');

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

% Create figure and tiled layout
fig = figure('Visible', Show, 'Position', [100, 100, cfg.figsize(1), cfg.figsize(2)], 'Color', 'white');
t = tiledlayout(cfg.layout(1), cfg.layout(2), 'TileSpacing', 'compact', 'Padding', 'tight');

% Concatenate trials into 3D matrix
dat = cat(3, data.trial{:}); % nchan x nsamples x ntrials
dat = dat(chanidx, :, :); % Select specified channels
avgdat = mean(dat, 3); % Mean across trials

% Return requested data
if strcmp(cfg.returnchanavg, 'yes')
    data.avgtime = mean(avgdat, 2);           
end

% Add main title
title(t, 'Single-Trial and Average Activity Across All Channels', 'FontSize', cfg.titlefontsize, 'FontWeight', 'bold');

% Plot data for each channel
for chan = 1:nchan
    nexttile;
    hold on;
    if strcmp(cfg.plotindividual, 'yes')
        % Plot all trials for this channel
        plot(data.time{1}, squeeze(dat(chan, :, :))', ...
             'Color', [0.7, 0.7, 0.7], 'LineWidth', 0.5);
    end
    if strcmp(cfg.plotmean, 'yes')
        % Plot mean for this channel
        plot(data.time{1}, avgdat(chan, :), ...
             'Color', [0, 0, 0], 'LineWidth', 2);
    end
    hold off;
    
    % Axis settings
    axis tight;
    title(data.label{chanidx(chan)}, 'FontSize', cfg.chantitlefontsize);

end

% Add axis labels
xlabel(t, 'Time (s)', 'FontSize', cfg.labelfontsize);
ylabel(t, 'Amplitude', 'FontSize', cfg.labelfontsize);

% Set outer margins
t.OuterPosition = cfg.outermargin;

% If plots are to be saved then save them
if strcmp(saveplots, 'yes')
    cfg_sp = [];
    cfg_sp.fig = fig;
    cfg_sp.plotname = 'trialchanavg';
    cfg_sp.main = main;
    cfg_sp.skip = skip;
    cfg_sp.plotfolder = plotfolder;
    savehandlefig(cfg_sp)
end 

end