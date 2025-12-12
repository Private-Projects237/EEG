function ft_plotcomptop(cfg, comp)
%FT_PLOTCOMPTOP This function will produce topography plots of the different 
% components produced by ICA.
%
% INPUTS
%   cfg.component  = 1:16 (default); Number of components to view
%   cfg.layout     = 'EEG1005.lay' (default); Based on your electrode layout
%   cfg.zilim      = 'maxabs' (default); Don't change this
%   cfg.warningmsg = 'off' (default); Turns of annoying warning messages 
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'component', 'layout', 'zilim'});

% Set up configuration defaults
component  = ft_getopt(cfg, 'component', 1:16);
layout     = ft_getopt(cfg, 'layout', 'EEG1005.lay');
zilim      = ft_getopt(cfg, 'zilim', 'maxabs');
warningmsg = ft_getopt(cfg, 'warningmsg', 'maxabs');

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

% Makes sure heat map is a byproduct of WITHIN component comparison
maxabs = max(abs(comp.topo), [], 1);           % 1×N vector
comp_norm = comp;                              % don't overwrite original
comp_norm.topo = bsxfun(@rdivide, comp.topo, maxabs);

% Now plot with fixed/symmetric limits
cfg = [];
cfg.component = component;
cfg.layout    = layout;
cfg.zlim      = zilim;   % or explicitly [-1 1], same result here

% Turn off warning messages if specified
if strcmp(warningmsg, 'off'); ft_warning off; end                

% Generate the topography plot
pause(.01);
fig = figure('Visible', Show, 'Position', [100 100 1200 800]);
ft_topoplotIC(cfg, comp_norm);

% Turn warning messages back on if turned off earlier
if strcmp(warningmsg, 'off'); ft_warning on; end

% If plots are to be saved then save them
if strcmp(saveplots, 'yes')
    cfg_sp = [];
    cfg_sp.fig = fig;
    cfg_sp.plotname = 'comptopplots';
    cfg_sp.main = main;
    cfg_sp.skip = skip;
    cfg_sp.plotfolder = plotfolder;
    savehandlefig(cfg_sp)
    pause(.02);
end

end