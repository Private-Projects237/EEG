function data = ft_robustdetrend2(cfg, data)
%FT_ROBUSTDETREND2 This function was designed to essentially clean sweat
% artifacts in the EEG data. It does this through robust detrending with the 
% `nt_detrend()` function from the NoiseTools toolbox, hence the name of the 
% function. There are two parts to this function, first it identifies segments
% (2 second trials) we suspect of having sweart artifacts based on large
% power values in the lower frequencies. We take those trials, incorporate an
% extra trial before and after it starts (buffer) and then run robust
% detrending on the artifact segments. 
%
% INPUT (Detect Sweat) - uses `detect_sweat_artifact()` 
%   cfg.robustdetrend2.zthresh        = 5.5 (default); Robust z-score of low frq amplitude (time domain)
%   cfg.robustdetrend2.minchan        = 3 (default); Min chan needed to be sweat artifact
%   cfg.robustdetrend2.mindur_sec     = 3 (default); Sec duration needed to be sweat artifact
%   cfg.robustdetrend2.buffer_sec     = 6 (default); Sec duration of extending segments (tail)
%   cfg.robustdetrend2.log            = 'no' (default);
%
% INPUT (robustdetrend) - uses `nt_detrend()` from NoiseTools Toolbox
%   cfg.robustdetrend2.order      = 10 (default); polynomial used by `nt_detrend()`
%   cfg.robustdetrend2.wsize_sec  = 2 (default); window length in seconds
%       for robust detrending
%
% INPUT (plots)
%   cfg.robustdetrend2.fullrecordingplots = 'no' (default); Plots the full recording
%       with suspected sweat artifact segments highlited (before and after)
%   cfg.robustdetrend2.segmentplots       = 'no' (default); Plots the segments
%       with suspected sweat artifacts (before and after)
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (defaul);
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% Output
%   data = A continuous dataset with no sweat artifacts

% Save the original configuration
cfg_org = cfg; 

% Check configuration for correct parameters
cfg = ft_checkconfig(cfg, 'required', {'robustdetrend2'});

% Set up configuration defaults
cfg.robustdetrend2 = ft_getopt(cfg, 'robustdetrend2', struct());
zthresh       = ft_getopt(cfg.robustdetrend2, 'zthresh', 5);
minchan       = ft_getopt(cfg.robustdetrend2, 'minchan', 8);
mindur_sec    = ft_getopt(cfg.robustdetrend2, 'mindur_sec', 1);
buffer_sec    = ft_getopt(cfg.robustdetrend2, 'buffer_sec', 6);
log           = ft_getopt(cfg.robustdetrend2, 'log', 'no');

order         = ft_getopt(cfg.robustdetrend2, 'order', 10);
wsize_sec     = ft_getopt(cfg.robustdetrend2, 'wsize_sec', 2);

fullrecordingplots = ft_getopt(cfg.robustdetrend2, 'fullrecordingplots', 'no');
segmentplots = ft_getopt(cfg.robustdetrend2, 'segmentplots', 'no');

visibleplots  = 'yes';
saveplots     = 'no';

% Overrite configuration if saveplot field (structure) specified
if isfield(cfg, 'saveplots')
    visibleplots = cfg.saveplots.visibleplots;
    saveplots    = cfg.saveplots.saveplots;
    skip         = cfg.saveplots.skip;
    plotfolder   = cfg.saveplots.plotfolder;
end

% Specify whether the plot is visible or not
if strcmp(visibleplots, 'yes'); Show = 'on'; else; Show = 'off'; end

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Identifying bad segments (not trials necessarily)
cfg_ds = [];
cfg_ds.detectsweat.zthresh       = zthresh;
cfg_ds.detectsweat.minchan       = minchan;
cfg_ds.detectsweat.mindur_sec    = mindur_sec;
cfg_ds.detectsweat.buffer_sec    = buffer_sec;

% Return boundaries of sweat artifacts
[boundaries] = detect_sweat_artifact(cfg_ds, data);

% Generate full plot is specified so
if strcmp(fullrecordingplots, 'yes')
    % Create a plot from the boundaries
    X = data.trial{:};
    
    % Generate the time domain figure
    fig = figure('Visible', Show, 'Position', [100 200 1200 800]); 
    ft_quickplot3(X);   
    ax = gca;  
    hold(ax, 'on'); 

    % Add boundary thresholds only if there are any present
    if ~isempty(boundaries)
        % Seperate boundaties into vectors
        artf_starts = boundaries(:,1); 
        artf_ends = boundaries(:, 2);
        
        % Add the highlighted regions (if any)
        for i = 1:length(artf_starts)
            patch(ax, [artf_starts(i) artf_ends(i) artf_ends(i) artf_starts(i)], ...
                         [ax.YLim(1) ax.YLim(1) ax.YLim(2) ax.YLim(2)], ...
                         'red', 'FaceAlpha', 0.35, 'EdgeColor', 'none');
        end
    end
    title('Detected Sweat Artifacts in the EEG data (Highlighted in Red)');
    hold(ax, 'off');

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'fulleegsweats';
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end 
    
end     

if ~isempty(boundaries)

    % If boundaries samples are outside the data- adjust them
    boundaries(boundaries < 1) = 1;
    maxsample = size(cat(2,data.trial{:}), 2);
    boundaries(boundaries > maxsample) = maxsample;
    
    % Indicate how many 'sweat' trials were identified
    sweat_seg_num = size(boundaries, 1);
    fprintf('%d sweat trials identified\n', sweat_seg_num);
    
    % Save the continuous data as X
    X = cat(2, data.trial{:});
    
    % Calculate the window length for nt_detrend()
    wsize_samp = round(wsize_sec * data.fsample);
    
    % Part 5: Robust detrend 'sweat' segments (including buffer trials/samples)
    for ii = 1:sweat_seg_num
        l = boundaries(ii,1); u = boundaries(ii,2);
        X_seg = X(:,l:u); % chann x sample
        X_seg_t = X_seg'; % sample x chann
        [X_seg_fixed_t, ~, ~] = nt_detrend(X_seg_t, order, [], 'polynomials', 3, 5, wsize_samp);
        
        % Introduce fixed data back into the dataset
        X_seg_fixed = X_seg_fixed_t';
        X(:,l:u) = X_seg_fixed; % chann x sample
    
        if strcmp(segmentplots, 'yes')
           
            fig = figure('Visible', Show); ft_quickplot3(X_seg); 
            title('Identified Sweat Artifact');
            % If plots are to be saved then save them
            if strcmp(saveplots, 'yes')
                cfg_sp = [];
                cfg_sp.fig = fig;
                cfg_sp.plotname = 'fulleegsweats';
                cfg_sp.skip = skip;
                cfg_sp.plotfolder = plotfolder;
                savehandlefig(cfg_sp)
            end 
            
            fig = figure('Visible', Show); ft_quickplot3(X_seg_fixed); 
            title('Robust Detrended Sweat Artifact');
            % If plots are to be saved then save them
            if strcmp(saveplots, 'yes')
                cfg_sp = [];
                cfg_sp.fig = fig;
                cfg_sp.plotname = 'fulleegsweats';
                cfg_sp.skip = skip;
                cfg_sp.plotfolder = plotfolder;
                savehandlefig(cfg_sp)
            end 
        end
    end
       
    % Introduce the fixed data back into the FieldTrip data objet
    data.trial{:} = X;
    
    % Generate full plot is specified so
    if strcmp(fullrecordingplots, 'yes')
    
        % Generate the time domain figure
        fig = figure('Visible', Show, 'Position', [100 200 1200 800]); 
        ft_quickplot3(X);   
        ax = gca;  
        hold(ax, 'on');   
        
        % Add the highlighted regions (if any)
        for i = 1:length(artf_starts)
            patch(ax, [artf_starts(i) artf_ends(i) artf_ends(i) artf_starts(i)], ...
                         [ax.YLim(1) ax.YLim(1) ax.YLim(2) ax.YLim(2)], ...
                         'red', 'FaceAlpha', 0.35, 'EdgeColor', 'none');
        end
        title('EEG Data after Sweat Artifact Removal');
        hold(ax, 'off');

        % If plots are to be saved then save them
        if strcmp(saveplots, 'yes')
            cfg_sp = [];
            cfg_sp.fig = fig;
            cfg_sp.plotname = 'fulleegsweats';
            cfg_sp.skip = skip;
            cfg_sp.plotfolder = plotfolder;
            savehandlefig(cfg_sp)
        end 

    end
else
    warning('No sweat artifacts present')
end

% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'rmvsweatartifc';
    fun_name = 'ft_robustdetrend2';

    % Prepare the stats structure
    stats = [];
    stats.sweatdetrendednum = size(boundaries,1);
    stats.successful = 'yes';

    % Generate the log for this function
    data = ft_logstep(data, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_robustdetrend2 log recorded\n');
end

end



