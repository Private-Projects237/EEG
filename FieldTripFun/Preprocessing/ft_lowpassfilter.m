function [data_lowfilt] = ft_lowpassfilter(cfg, data)
% FT_LOWPASSFILTER Low pass filters the data (throws our very high
% frequency information from the data).This function directly uses FieldTrip
% `ft_preprocessing()`- and was created mainly for logging purposes. 
%
% INPUT
%   cfg.lowpassfilt.lpfilter   = 'yes' (default); Does the low-pass filter
%   cfg.lowpassfilt.lpfreq     = 100 (default); Cut-off in frequency
%   cfg.lowpassfilt.lpfiltord  = 4 (default); Filter order
%   cfg.lowpassfilt.lpfiltype  = 'but' (default)'; but = butterworh; other options = firws, fir, firls 
%   cfg.lowpassfilt.lpfiltdir  = 'twopass' (default);
%   cfg.lowpassfilt.log        = 'no' (default);
%
% INPUT (plots)
%   cfg.lowpassfilt.fullrecordingplots = 'no' (default); Plots the full recording
%       before and after low-pass filtering
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
cfg = ft_checkconfig(cfg, 'required', {'lowpassfilt'});

% Set up configuration defaults
cfg.lowpassfilt = ft_getopt(cfg, 'lowpassfilt', struct());
lpfilter      = ft_getopt(cfg.lowpassfilt, 'lpfilter', 'yes');
lpfreq        = ft_getopt(cfg.lowpassfilt, 'lpfreq', 100);
lpfiltord     = ft_getopt(cfg.lowpassfilt, 'lpfiltord', 4);
lpfiltype     = ft_getopt(cfg.lowpassfilt, 'lpfiltype', 'but');
lpfiltdir     = ft_getopt(cfg.lowpassfilt, 'lpfiltdir', 'twopass');
log           = ft_getopt(cfg.lowpassfilt, 'log', 'no');

fullrecordingplots = ft_getopt(cfg.lowpassfilt, 'fullrecordingplots', 'no');

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

% Create a structure needed to do low-pass filtering
cfg = [];
cfg.lpfilter   = lpfilter;     
cfg.lpfreq     = lpfreq;       
cfg.lpfiltord  = lpfiltord;          
cfg.hpfilttype = lpfiltype;      
cfg.lpfiltdir  = lpfiltdir;  

% Low-pass filtered data
data_lowfilt = ft_preprocessing(cfg, data);

% Generate plots of the EEG data before and after low-pass filtering
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
    title('EEG Before Low-Pass Filtering');
    xlabel('Time (s)');
    set(gcf, 'Position', [100, 100, 1000, 800]);

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'beforelowpassfilt';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

    % Prepare the second plot
    X2 = data_lowfilt.trial{:}; t = data.time{:};
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
    title('EEG After Low-Pass Filtering');
    xlabel('Time (s)');
    set(gcf, 'Position', [100, 100, 1000, 800]);

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'afterlowpassfilt';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

end


% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'lowpassfilt';
    fun_name = 'ft_lowpassfilter';

    % Prepare the stats structure
    stats = [];
    stats.successful = 'yes';

    % Generate the log for this function
    data_lowfilt = ft_logstep(data_lowfilt, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_lowpassfilter log recorded\n');
end

end




