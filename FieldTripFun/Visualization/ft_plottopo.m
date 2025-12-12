function ft_plottopo(cfg, data)
% FT_PLOTTOPO: Plot 6 EEG topoplots in ONE figure (ALL VISIBLE)
%
% cfg.layout = 'EEG1005.lay' (string)
% data has: avgtime, avgfft, avgdelta, avgtheta, avgalpha, avgbeta, label
%
% Forces each plot into its subplot using: axes() + cla() + cfg.
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within

% Validate input
if ~isstruct(data) || ~all(isfield(data, {'avgtime','avgfft','avgdelta','avgtheta','avgalpha','avgbeta','label'}))
    error('data must have: avgtime, avgfft, avgdelta, avgtheta, avgalpha, avgbeta, label');
end

% Setting short cut variables from cfg
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

% Extract data
fields = {'avgtime', 'avgfft', 'avgdelta', 'avgtheta', 'avgalpha', 'avgbeta'};
titles = {'Time', 'Frequency', 'delta', 'theta', 'alpha', 'beta'};
values = cell(1,6);
for i = 1:6
    values{i} = data.(fields{i});
end

% Create figure
fig = figure('Visible', Show, 'Units','normalized','Position',[0.05 0.1 0.9 0.7]);

% Define subplot positions
ax(1) = axes('Position', [0.02 0.15 0.30 0.70]);  % Time
ax(2) = axes('Position', [0.35 0.15 0.30 0.70]);  % Frequency
ax(3) = axes('Position', [0.69 0.58 0.13 0.30]);  % delta
ax(4) = axes('Position', [0.84 0.58 0.13 0.30]);  % theta
ax(5) = axes('Position', [0.69 0.15 0.13 0.30]);  % alpha
ax(6) = axes('Position', [0.84 0.15 0.13 0.30]);  % beta

% Plot each topo — FORCE into correct axes
for i = 1:6
    % CRITICAL: Clear and activate the correct axes
    cla(ax(i), 'reset');
    set(fig, 'CurrentAxes', ax(i));  % Force current axes
    
    % Build topo
    topo = struct();
    topo.avg = values{i};
    topo.label = data.label;
    topo.dimord = 'chan';
    
    % Copy cfg
    cfg_plot = cfg;
    %cfg_plot.zlim = [0, max(values{i}(:)) * 1.1];
    cfg_plot.zlim = [0, max(abs(values{i}(:))) * 1.1];
    cfg_plot.parameter = 'avg';
    cfg_plot.colorbar = 'no';
    cfg_plot.colormap = flipud(brewermap(64, 'RdBu')); % Experimental 
    
    % THIS IS THE KEY: Force plot into THIS axes
    cfg_plot.figure = ax(i);
    
    % Plot
    ft_topoplotER(cfg_plot, topo);
    
    % Title
    title(ax(i), titles{i}, 'FontWeight','bold', 'FontSize',11);
end

% Add colorbars to big panels
colorbar(ax(1), 'Location','southoutside');
colorbar(ax(2), 'Location','southoutside');

% Overall title
sgtitle('EEG Topography (Comprehensive Descriptives)', 'FontSize',14, 'FontWeight','bold');

% If plots are to be saved then save them
if strcmp(saveplots, 'yes')
    cfg_sp = [];
    cfg_sp.fig = fig;
    cfg_sp.plotname = 'TopographyAllFrqgBands';
    cfg_sp.main = main;
    cfg_sp.skip = skip;
    cfg_sp.plotfolder = plotfolder;
    savehandlefig(cfg_sp)
end 

end