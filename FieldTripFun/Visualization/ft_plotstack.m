function ft_plotstack(cfg, data)
%ft_plotstack  Stacked montage: whole recording by default, single trial if requested
%   ft_plotstack(cfg, data)
%
% INPUT
%   cfg.channel   = {'Fz','O1',...} or 'all' (default 'all')
%   cfg.trial     = scalar (e.g. 5) OR omitted → full recording
%   cfg.center    = 'yes'
%   cfg.color     = [r g b] (default black)
%   cfg.title     = string (default auto)
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within


% Default configuration
cfg = ft_checkconfig(cfg, 'required', {'channel', 'trial', 'center'});

% Set cfg defaults
channel      = ft_getopt(cfg, 'channel', 'all');
trial        = ft_getopt(cfg, 'trial', 'all');
center       = ft_getopt(cfg, 'center', 'yes');

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

% Pick trials
if isequal(trial,'all')
    X    = cat(2, data.trial{:});
    time = zeros(1,size(X,2)); p=1;
    for i=1:numel(data.trial)
        n = numel(data.time{i});
        time(p:p+n-1) = data.time{i} + (p-1)/data.fsample;
        p = p + n;
    end
else
    X    = data.trial{trial};
    time = data.time{trial};
end

% Pick channels
if ischar(channel) && strcmp(channel,'all')
    Y = X;
else
    [idx,~] = match_str(channel, data.label);
    Y = X(idx,:);
end

% Center the Y variable before plotting
if isequal(center, 'yes')
    Y = Y - mean(Y,2);
end 

% Generate a figure and save it within 'fig'
fig = figure('Visible', Show, 'Color', 'w');

% Specifics of the plot
plot(time, Y', 'LineWidth',1.1); hold on;
colormap(parula(size(Y,1)));   % 1 color per channel
grid on; box on;
xlabel('Time (s)'); ylabel('Amplitude (µV)');
title('Centered Amplitude by Channels', 'FontWeight','bold');
xlim([time(1) time(end)]);
set(gcf, 'Position', [100, 100, 750, 550]) %  750px wide and 550px tall
hold off;

% If plots are to be saved then save them
if strcmp(saveplots, 'yes')
    cfg_sp = [];
    cfg_sp.fig = fig;
    cfg_sp.plotname = 'stack';
    cfg_sp.main = main;
    cfg_sp.skip = skip;
    cfg_sp.plotfolder = plotfolder;
    savehandlefig(cfg_sp)
end 

end