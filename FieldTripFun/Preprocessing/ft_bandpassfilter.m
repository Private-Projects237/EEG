function [data_highfilt] = ft_bandpassfilter(cfg, data)
% FT_BANDPASSFILTER Band pass filters the data (throws our very low
% frequency information and very high frequency informationfrom the data). 
% Very useful for a quick way to clean data overall. However, this will attenuate
% noise in general- making it harder for other functions to detect them.
% But, if the thresholds are at the farther edges of the spectrum, then it
% should help more than debilitate. This function directly uses FieldTrip 
% `ft_preprocessing()`- and was created mainly for logging purposes. 
%
% INPUT
%   cfg.bandpassfilt.bpfilter   = 'yes' (default); Does the high-pass filter
%   cfg.bandpassfilt.bpfreq     = [1 100] (default); Cut-off in frequency
%   cfg.bandpassfilt.bpfiltord  = 4 (default); Filter order
%   cfg.bandpassfilt.bpfilttype  = 'but' (default)'; but = butterworh; other options = firws, fir, firls 
%   cfg.bandpassfilt.bpfiltdir  = 'twopass' (default);
%   cfg.bandpassfilt.log        = 'no' (default);
%
% INPUT (plots)
%   cfg.bandpassfilt.fullrecordingplots = 'no' (default); Plots the full recording
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
cfg = ft_checkconfig(cfg, 'required', {'bandpassfilt'});

% Set up configuration defaults
cfg.bandpassfilt = ft_getopt(cfg, 'bandpassfilt', struct());
bpfilter      = ft_getopt(cfg.bandpassfilt, 'bpfilter', 'yes');
bpfreq        = ft_getopt(cfg.bandpassfilt, 'bpfreq', [1 100]);
bpfiltord     = ft_getopt(cfg.bandpassfilt, 'bpfiltord', 4);
bpfilttype    = ft_getopt(cfg.bandpassfilt, 'bpfilttype', 'but');
bpfiltdir     = ft_getopt(cfg.bandpassfilt, 'bpfiltdir', 'twopass');
log           = ft_getopt(cfg.bandpassfilt, 'log', 'no');

fullrecordingplots = ft_getopt(cfg.bandpassfilt, 'fullrecordingplots', 'no');

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
cfg.bpfilter   = bpfilter;     
cfg.bpfreq     = bpfreq;       
cfg.bpfiltord  = bpfiltord;          
cfg.bpfilttype = bpfilttype;      
cfg.bpfiltdir  = bpfiltdir;  

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
    title('EEG Before Band-Pass Filtering');
    xlabel('Time (s)');
    set(gcf, 'Position', [100, 100, 1000, 800]);

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'beforebandpassfilt';
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
    title('EEG After Band-Pass Filtering');
    xlabel('Time (s)');
    set(gcf, 'Position', [100, 100, 1000, 800]);

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'afterbandpassfilt';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

end


% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'bandpassfilt';
    fun_name = 'ft_bandpassfilter';

    % Prepare the stats structure
    stats = [];
    stats.successful = 'yes';

    % Generate the log for this function
    data_highfilt = ft_logstep(data_highfilt, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_bandpassfilter log recorded\n');
end

end




