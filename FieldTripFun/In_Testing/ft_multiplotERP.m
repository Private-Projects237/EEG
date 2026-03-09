function ft_multiplotERP(cfg, data)
% FT_MULTIPLOTERP This custom function plots ERPs across all channels in
% the data. It is basically the FieldTrip `ft_multiplotER()` function,
% except we can customize the size of the plot and save it as a PNG. The
% data input should be a structure that is generated from using the 
% `ft_timelockanalysis()` function, where the field `.avg` is present!
%
% INPUT
%   cfg.layout       = 'standard_1005.elc' (default)
%   cfg.showoutline  = 'yes' (default)
%   cfg.fontsize     = 12 (default)          
%   cfg.labeloffset  = 0.02 (default); % slight spacing tweak if labels overlap
%   cfg.comment      = 'auto' (default) 
%   cfg.plotsize     = [100 100 1600 1000] (default);  [left bottom width height] in pixels
%   cfg.erpname      = 'MMN'; the name of the ERP
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
showoutline = ft_getopt(cfg, 'showoutline', 'yes');
fontsize    = ft_getopt(cfg, 'fontsize', 12);
labeloffset = ft_getopt(cfg, 'labeloffset', 0.02);
plotsize    = ft_getopt(cfg, 'plotsize', [100 100 1600 1000]);
erpname     = ft_getopt(cfg, 'erpname', 'ERP');

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

% Control the figure size
fig = figure('Visible', Show, 'Position', plotsize);

% Create a title
time_start = data.time(1) * 1000;  % convert to ms for readability
time_end   = data.time(end) * 1000;
comment_str = sprintf('%s (%.0f to %.0f ms)', erpname, time_start, time_end);

% Create the structure to generate the plot
cfg = [];
cfg.layout       = layout;
cfg.showoutline  = showoutline;
cfg.fontsize     = fontsize;          
cfg.labeloffset  = labeloffset;  

% Create a title for the plot
cfg.comment     = comment_str;   % the text to display
cfg.commentpos  = 'title';       % place it as figure title

% This is needed to increase the size of the plot
cfg.figure       = fig;         

% Generate the ERP for all electrodes in the data
ft_multiplotER(cfg, data);
title(comment_str, 'FontSize', 16, 'FontWeight', 'bold');

% If plots are to be saved then save them
if strcmp(saveplots, 'yes')
    cfg_sp = [];
    cfg_sp.fig = fig;
    cfg_sp.plotname = 'plotERPallchans';
    cfg_sp.main = main;
    cfg_sp.skip = skip;
    cfg_sp.plotfolder = plotfolder;
    savehandlefig(cfg_sp)
    pause(.02);
end
    

end