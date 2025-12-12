function data_rmvlinenoise = ft_removelinenoise(cfg, data)
% FUNCTION Removes line noise using the `ft_preprocessing()` function. We
% created a custom function just to log the information.
%
% INPUT
%   cfg.rmvlinenoise.dftfilter    = 'yes' (default); 
%   cfg.rmvlinenoise.dftfreq      = [60 120 180] (US: default); 
%   cfg.rmvlinenoise.dftreplace   = 'zero' (default);
%   cfg.rmvlinenoise.dftbandwidth =  1 (default);
%   cfg.rmvlinenoise.log          = 'no' (default);
%   cfg.rmvlinenoise.rmvlineplot  = 'no' (defualt); Shows frq plot before and after
%
% INPUT (Optional)
%   cfg.rmvlinenoise.bsfilter   = 'yes' or 'no'; (default is no)
%   cfg.rmvlinenoise.bsfreq     = [58 62]; % or [48 61] (USE) 
%   cfg.rmvlinenoise.bsfiltord  = 4;
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% OUTPUT
%   data_rmvlinenoise = data 

% Save the original configuration
cfg_org = cfg; 

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'rmvlinenoise'});

% Set up configuration defaults
cfg.rmvlinenoise = ft_getopt(cfg, 'rmvlinenoise', struct());
dftfilter        = ft_getopt(cfg.rmvlinenoise, 'dftfilter', 'yes');
dftfreq          = ft_getopt(cfg.rmvlinenoise, 'dftfreq', [60 120 180]);
dftreplace       = ft_getopt(cfg.rmvlinenoise, 'dftreplace', 'zero');
dftbandwidth     = ft_getopt(cfg.rmvlinenoise, 'dftbandwidth', 1);
log              = ft_getopt(cfg.rmvlinenoise, 'log', 'no');
rmvlineplot      = ft_getopt(cfg.rmvlinenoise, 'rmvlineplot', 'no');

bsfilter         = ft_getopt(cfg.rmvlinenoise, 'bsfilter', 'no');
bsfreq           = ft_getopt(cfg.rmvlinenoise, 'bsfreq', [58 62]);
bsfiltord        = ft_getopt(cfg.rmvlinenoise, 'bsfiltord', 4);

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

% Create a struct to remove line noise
cfg              = [];
cfg.dftfilter    = dftfilter;        % Use DFT (notch) filter
cfg.dftfreq      = dftfreq; % 60 Hz fundamental + 1st, 2nd harmonics (US power)
cfg.dftreplace   = dftreplace;       % Zero out exact frequencies (default: 'neighbour')
cfg.dftbandwidth = dftbandwidth;            % ±0.5 Hz around each freq (default: 1 Hz total)

% Remove line noise 
data_rmvlinenoise = ft_preprocessing(cfg, data);  

% Optional additional removing line noise
if strcmp(bsfilter, 'yes')
    cfg = [];
    cfg.bsfilter   = bsfilter;
    cfg.bsfreq     = bsfreq;             
    cfg.bsfiltord  = bsfiltord;  % Butterworth xth order
    data_rmvlinenoise = ft_preprocessing(cfg, data_rmvlinenoise);
end

% If specified- generate plots
if strcmp(rmvlineplot, 'yes')
    
    % Compute the frequency resolution
    smpfrq = data.fsample;
    len = size(data.trial{1},2)/smpfrq;
    freq_res = 1/len; % Frequency resolution

    % Compute the power spectrum for original and notch filtered data
    cfg_ps            = [];
    cfg_ps.method     = 'mtmfft';
    cfg_ps.output     = 'pow';
    cfg_ps.taper      = 'hanning';
    cfg_ps.foi        = 1:freq_res:130;
    cfg_ps.pad        = 'nextpow2';
    freq1  = ft_freqanalysis(cfg_ps, data);
    
    % Create a structure to plot the data using `ft_singleplotER()`
    cfg_plot               = [];
    cfg_plot.channel       = 'all';
    cfg_plot.showlabels    = 'no';
    cfg_plot.xlim          = [45 130];
    cfg_plot.zlim          = [-15 40];   
    cfg_plot.colormap      = parula;
    cfg_plot.colorbar      = 'yes';      % optional, nice to have
    
    % Plot the original dataset
    fig = figure('Visible', Show, 'Position', [300 400 600 500]);
    ft_singleplotER(cfg_plot, freq1);    
    title('EEG Power Across Frequencies Before Notch Filter');
    xlabel('Frequency (Hz)');
    grid on;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'beforelinenoisermv';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

    % Add a pause to prevent disorder between plots
    pause(.5);
    freq2  = ft_freqanalysis(cfg_ps, data_rmvlinenoise);

    % Plot the corrected dataset
    fig = figure('Visible', Show, 'Position',  [900 400 600 500]);
    ft_singleplotER(cfg_plot, freq2);    
    title('EEG Power Across Frequencies After Notch Filter');
    xlabel('Frequency (Hz)');
    grid on;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'afterlinenoisermv';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end
end


% if log is needed generate this output
if strcmp(log, 'yes')

    % Prepare function name and what it does
    step_name = 'rmvlinenoise';
    fun_name = 'ft_removelinenoise';

    % Prepare the stats structure
    stats = [];
    stats.linenoisehz = dftfreq;
    stats.bsfilter = bsfilter;
    stats.successful = 'yes';

    % Generate the log for this function
    data_rmvlinenoise = ft_logstep(data_rmvlinenoise, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_removelinenoise log recorded\n');

end


end