function [data_highfilt] = ft_highpassfilter(cfg, data)
% FT_HIGHPASSFILTER High pass filters the data (throws our very low
% frequency information from the data). Very useful for recordings that
% have high sweat/body movement artifacts. However, this will attenuate
% noise in general- making it harder for other functions to detect them.
% This function directly uses FieldTrip `ft_preprocessing()`- and was
% created mainly for logging purposes. 
%
% INPUT
%   cfg.highpassfilt.hpfilter   = 'yes' (default); Does the high-pass filter
%   cfg.highpassfilt.hpfreq     = 0.5 (default); Cut-off in frequency
%   cfg.highpassfilt.hpfiltord  = 4 (default); Filter order
%   cfg.highpassfilt.hpfiltype  = 'but' (default)'; but = butterworh; other options = firws, fir, firls 
%   cfg.highpassfilt.hpfiltdir  = 'twopass' (default);
%   cfg.highpassfilt.log        = 'no' (default);
%
% INPUT (plots)
%   cfg.highpassfilt.fullrecordingplots = 'no' (default); Plots the full recording
%       before and after high-pass filtering
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within


% Save the original configuration
cfg_org = cfg; 

% Check configuration for correct parameters
cfg = ft_checkconfig(cfg, 'required', {'highpassfilt'});

% Set up configuration defaults
cfg.highpassfilt = ft_getopt(cfg, 'highpassfilt', struct());
hpfilter      = ft_getopt(cfg.highpassfilt, 'hpfilter', 'yes');
hpfreq        = ft_getopt(cfg.highpassfilt, 'hpfreq', 0.5);
hpfiltord     = ft_getopt(cfg.highpassfilt, 'hpfiltord', 4);
hpfiltype     = ft_getopt(cfg.highpassfilt, 'hpfiltype', 'but');
hpfiltdir     = ft_getopt(cfg.highpassfilt, 'hpfiltdir', 'twopass');
log           = ft_getopt(cfg.highpassfilt, 'log', 'no');

fullrecordingplots = ft_getopt(cfg.highpassfilt, 'fullrecordingplots', 'no');

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
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Create a structure needed to do high-pass filtering
cfg = [];
cfg.hpfilter   = hpfilter;     
cfg.hpfreq     = hpfreq;       
cfg.hpfiltord  = hpfiltord;          
cfg.hpfilttype = hpfiltype;      
cfg.hpfiltdir  = hpfiltdir;  

% High-pass filtered data
data_highfilt = ft_preprocessing(cfg, data);

% Generate plots of the EEG data before and after high-pass filtering
if strcmp(fullrecordingplots, 'yes')
    X1 = data.trial{:}; t = data.time{:};
    offset = 30 * median(abs(X1(:)-median(X1(:))));                    
    colors = lines(size(X1,1));             
    rng(157); colors = colors(randperm(size(X1,1)), :);
    
    % Generate the figure 
    fig = figure('Visible', Show, 'Color', 'w'); 
    plot(t, X1 + (0:size(X1,1)-1)'*offset, 'LineWidth',1.3);
    set(gca, 'ColorOrder', colors, ...
             'YTick', 0:offset:(size(X1,1)-1)*offset, ...
             'YTickLabel', data.label, 'YDir','reverse', 'Box','off');
    grid on;
    title('EEG Before High-Pass Filtering');
    xlabel('Time (s)');
    set(gcf, 'Position', [100, 100, 1000, 800]);

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'beforehighpassfilt';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

    % Prepare the second plot
    X2 = data_highfilt.trial{:}; t = data.time{:};
    offset = 30 * median(abs(X2(:)-median(X2(:))));                   
    colors = lines(size(X2,1));             
    rng(157); colors = colors(randperm(size(X2,1)), :);
    
    % Generate the figure 
    fig = figure('Visible', Show, 'Color', 'w'); 
    plot(t, X2 + (0:size(X2,1)-1)'*offset, 'LineWidth',1.3);
    set(gca, 'ColorOrder', colors, ...
             'YTick', 0:offset:(size(X2,1)-1)*offset, ...
             'YTickLabel', data.label, 'YDir','reverse', 'Box','off');
    grid on;
    title('EEG After High-Pass Filtering');
    xlabel('Time (s)');
    set(gcf, 'Position', [100, 100, 1000, 800]);

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'afterhighpassfilt';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

end


% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'highpassfilt';
    fun_name = 'ft_highpassfilter';

    % Prepare the stats structure
    stats = [];
    stats.successful = 'yes';

    % Generate the log for this function
    data_highfilt = ft_logstep(data_highfilt, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_highpassfilter log recorded\n');
end

end




