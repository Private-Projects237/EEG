function ft_plotERPtopo(cfg, data)
% FT_PLOTERPTOPO Custom FieldTrip-style function that takes in ERP data
% from using `ft_timelockanalysis()`, preferrable a difference in the .avg
% field between two ERPs, and produces a topographical map using the
% FieldTrip `ft_topoplotER()` function. The main purpose for this custom
% function is to add more customization plus be compatible with saving the
% produced plot as a PNG.
%
% INPUT
%   cfg.layout  = 'standard_1005.elc' (default); the layout of the electrodes
%   cfg.xlim    = [0.1 0.25] (default); A range of the x-axis in ms
%   cfg.erpname = 'MMN'; the name of the ERP
%   cfg.zlim = [-3 3]; the range of microvolts for the topography color
%   cfg.colormap = 'parula'; the color shown (can also use 'jet')
%   cfg.colorbar = 'yes' or 'southoutside'; shows a color bar
%   cfg.colorbartext = 'µV'; the label for the colorbar
%
% INPUT (data)
%   Must be a structure created by `ft_timelockanalysis()`
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%

% Set up configuration defaults
layout      = ft_getopt(cfg, 'layout', 'standard_1005.elec');
xlim        = ft_getopt(cfg, 'xlim', [0.1 0.25]);
erpname     = ft_getopt(cfg, 'erpname', 'ERP');
zlim         = ft_getopt(cfg, 'zlim', [-3 3]);     % Constrain microvolt range
colormap     = ft_getopt(cfg, 'colormap', 'parula');   % or 'jet'
colorbar     = ft_getopt(cfg, 'colorbar', 'southoutside'); % Places label at the bottom
colorbartext = ft_getopt(cfg, 'colorbartext', []);   % label on the color bar

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


% Convert the xlim to milliseconds (ms) for plotting
time_start = xlim(1) * 1000;  % convert to ms for readability
time_end   = xlim(2) * 1000;
comment_str = sprintf('%s (%.0f - %.0f ms)', erpname, time_start, time_end);

% Generate the topography plot
cfg_topo = [];
cfg_topo.layout = layout;
cfg_topo.xlim = xlim;
cfg_topo.zlim         = zlim;                  
cfg_topo.colormap     = colormap;                     
cfg_topo.marker       = 'on';
cfg_topo.markersymbol = 'o';
cfg_topo.markercolor  = [0 0 0];
cfg_topo.colorbar     = colorbar;                     
cfg_topo.colorbartext = colorbartext;                    


% Create a title for the plot
cfg_topo.comment     = comment_str;   % the text to display
cfg_topo.commentpos  = 'title';       % place it as figure title

% Generate the topography plot
fig = figure('Visible', Show);
ft_topoplotER(cfg_topo, data)
title(comment_str, 'FontSize', 16, 'FontWeight', 'bold');

% If plots are to be saved then save them
if strcmp(saveplots, 'yes')
    cfg_sp = [];
    cfg_sp.fig = fig;
    cfg_sp.plotname = 'plotERPtopo';
    cfg_sp.main = main;
    cfg_sp.skip = skip;
    cfg_sp.plotfolder = plotfolder;
    savehandlefig(cfg_sp)
    pause(.02);
end
    
end






