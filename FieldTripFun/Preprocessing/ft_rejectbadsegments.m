function data_rej = ft_rejectbadsegments(cfg, data)
% FT_REJECTBADSEGMENTS This function uses trial variance over median trial
% variance ratios and robust z-scores of high frq band-pass filtered data
% to identidy noisy trials and not keeps them! All variance comparisons are
% done in the time domain not frequency domain. Additionally, we can
% 'save' bad trials if only a few channels are contributing to their high
% variance- thus allowing for these channels to be interpolate in future
% steps, saving the trial from unnecessary deletion.
%
% UPDATE
%   Initially we used the `ft_rejectartifact()` to remove bad segments, but
%   that caused problems when epoches overlapped. To circumvent this, we
%   are now using `ft_selectdata()` to keep good trials instead.
%
% INPUT
%   data = continuous or segmented EEG data
% 
% INPUT (Data Structure)
%   cfg.removebadchann.datatype       = 'rseeg' or 'erp'
%   cfg.removebadchann.seglength      = 2 (default); only applies to 'rseeg' will be ignored in 'erp'
%
% INPUT (Artifact Thresholds)
%   cfg.rejectbadseg.mthresh          = 5 (default); x times larger than median trial variace
%   cfg.rejectbadseg.highfrqbp        = [30 140] (default): band-pass filter to detect muscles or high artifact
%   cfg.rejectbadseg.zthresh          = 3.5 (default); Robust z-score thresh
%   cfg.rejectbadseg.savetrials       = 'yes' (default); Saves high var trials if its due to a few channels
%   cfg.rejectbadseg.chanprop         = 0.20 (default); Proportion of channels that will be investigated for trial var contribution
%   cfg.rejectbadseg.zchanpropvar      = 2.5 (default); Robust z-scores higher than thresh indicate few chans are inflating trial variance
%
%   cfg.rejectbadseg.badsegplot       = 'no' (default); Creates a stem plot of identified bad trials
%   cfg.rejectbadseg.indvbadsegplot   = 'no' (default): Creates individual plots of bad trials
%   cfg.rejectbadseg.onegoodplot      = 'no' (default): Generates a median variance trial plot (good plot)
%   cfg.rejectbadseg.log              = 'no' (default);
%   cfg.rejectbadseg.intpmatrixupdt   = 'no' (default); creates/updates intpmatrix field
%
% INPUT (Special - Recommended for Eyes Open)
%   cfg.rejectbadseg.peakprotection = 'no' (default); Attenuates blink
%       amplitudes for specified channels when calculating electrode pop
%       variance.
%   cfg.rejectbadseg.blinkchans     = {}; cell array (ex: {'Fp1', 'Fp2'}
%   cfg.rejectbadseg.attenblnkplot  = 'no' (default);
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%       
% OUPUT
%   data_rej = segmented EEG data in FieldTrip framework with bad trials removed

% Creating a vector of allowed datatypes
allowed_datatypes = {'rseeg', 'erp'};

% Save the original configuration
cfg_org = cfg; 

% Check configuration for correct parameters
cfg = ft_checkconfig(cfg, 'required', {'rejectbadseg'});

% Set up configuration defaults
cfg.rejectbadseg = ft_getopt(cfg, 'rejectbadseg', struct());
datatype         = ft_getopt(cfg.rejectbadseg, 'datatype', []);
seglength        = ft_getopt(cfg.rejectbadseg, 'seglength', 2);

mthresh          = ft_getopt(cfg.rejectbadseg, 'mthresh', 5);
highfrqbp        = ft_getopt(cfg.rejectbadseg, 'highfrqbp', [30 140]);
zthresh          = ft_getopt(cfg.rejectbadseg, 'zthresh', 3.5);
savetrials       = ft_getopt(cfg.rejectbadseg, 'savetrials', 'yes');
chanprop         = ft_getopt(cfg.rejectbadseg, 'chanprop', 0.20);
zchanpropvar     = ft_getopt(cfg.rejectbadseg, 'zchanpropvar', 2.5);

badsegplot       = ft_getopt(cfg.rejectbadseg, 'badsegplot', 'no');
indvbadsegplot   = ft_getopt(cfg.rejectbadseg, 'indvbadsegplot', 'no');
onegoodplot      = ft_getopt(cfg.rejectbadseg, 'onegoodplot', 'no');   
log              = ft_getopt(cfg.rejectbadseg, 'log', 'no');
intpmatrixupdt   = ft_getopt(cfg.rejectbadseg, 'intpmatrixupdt', 'no');

peakprotection      = ft_getopt(cfg.rejectbadseg, 'peakprotection', 'no');
blinkchans          = ft_getopt(cfg.rejectbadseg, 'blinkchans', []);
attenblnkplot       = ft_getopt(cfg.rejectbadseg, 'attenblnkplot', 'no');

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

% Error management
if ~any(strcmp(datatype, allowed_datatypes))
    error('cfg.rejectbadseg.datatype must be one of: ''rseeg'' or ''erp''. Got: ''%s''.', datatype);
end


% Best for eyes open conditions
if strcmp(peakprotection, 'yes')

    % Create a structure to run the ft_attenuatepeaks() function
    cfg_atten = [];
    cfg_atten.attenuatepeaks.channel       = blinkchans;
    cfg_atten.attenuatepeaks.zthresh       = 3;
    cfg_atten.attenuatepeaks.maxdur        = 0.5;
    cfg_atten.attenuatepeaks.padding       = 50; 
    cfg_atten.attenuatepeaks.interbuffer   = 20;
    cfg_atten.attenuatepeaks.attenblnkplot = attenblnkplot;
    cfg_atten.attenuatepeaks.plotzoom      = 6;

    % If saveplots is specified- add this into ft_attenuatepeaks
    if isfield(cfg, 'saveplots')
        cfg_atten.saveplots.visibleplots  = visibleplots;
        cfg_atten.saveplots.saveplots     = saveplots;
        cfg_atten.saveplots.main          = main;
        cfg_atten.saveplots.skip          = skip;
        cfg_atten.saveplots.plotfolder    = plotfolder;
    end

    % Return a matrix of attenuated channels
    temp_dat = ft_attenuatepeaks(cfg_atten, data);

else
    % Save the data object as something esle
    temp_dat = data;
end


%%%%%%%%%%%%%% IDENTIFY POTENTIALLY BAD TRIALS TIME %%%%%%%%%%%%%%%%%%

% Segment the data into a TEMPORAY DATA SET
if strcmp(datatype, 'rseeg')
    cfg_seg = [];
    cfg_seg.length  = seglength; % segment (trial) length in seconds
    cfg_seg.overlap = 0;         % 0% overlap
    data_seg_temp = ft_redefinetrial(cfg_seg, temp_dat);
elseif strcmp(datatype, 'erp')
    data_seg_temp = temp_dat;
end

% step 3: calculate the variance for each trial
nTrials   = numel(data_seg_temp.trial);
nChans    = numel(data_seg_temp.label);         
var_per_trial = nan(nTrials, nChans);
for i = 1:nTrials
    this_trial = data_seg_temp.trial{i};         % chan × time_i
    var_per_trial(i, :) = var(this_trial, 0, 2);  % variance along time (dim 2), for each channel
end

% Get the trial variance to median trial variance ratio
med_var = median(var_per_trial);
ratio_to_med = var_per_trial / med_var;

% Get the index of the trials that are problematic
bad_trials = find(ratio_to_med > mthresh)';

%%%%%%%%%%%%%% IDENTIFY POTENTIALLY BAD TRIALS BAND-PASS FILT %%%%%%%%%%%%%%

% band-pass filter high frequency information
cfg_filt = [];
cfg_filt.bpfilter   = 'yes';
cfg_filt.bpfreq     = highfrqbp;
cfg_filt.bpfiltord  = 4;          
cfg_filt.padding    = 2;           
cfg_filt.padtype    = 'mirror';   
dat_filt = ft_preprocessing(cfg_filt, data_seg_temp);

% step 3: calculate the variance for each trial
nTrials   = numel(dat_filt.trial);
nChans    = numel(dat_filt.label);         
trial_var = nan(nTrials, nChans);
for i = 1:nTrials
    this_trial = dat_filt.trial{i};         % chan × time_i
    trial_var(i, :) = var(this_trial, 0, 2);  % variance along time (dim 2), for each channel
end

% step 4: identify artifact trials using robust z-scores (exceeds z-thresh)
median_val = median(trial_var);
MAD_val    = median(abs(trial_var - median_val));
if MAD_val == 0, MAD_val = eps; end
z_pow = 0.6745 * (trial_var - median_val) / MAD_val;

% Identify bad trials by having too much variance
bad_trials2 = find(abs(z_pow) > zthresh)';

% Update bad channel vector and keep only unique trials
bad_trials = unique([bad_trials, bad_trials2]);

% Create a vector of good trials
good_trials = setdiff(1:numel(data_seg_temp.trial), unique([bad_trials bad_trials2]));

% For each trial check how much variance is explained by chan prop threshold
chan_var_prop = [];

for ii = 1:numel(data_seg_temp.trial)

    % Extract current trial
    current_trial = data_seg_temp.trial{ii};

    % Obtain the variance for each electrode
    chan_var = var(current_trial, [], 2);
    total_var_sum = sum(chan_var);          % 14
    var_prop = (chan_var / total_var_sum);
    var_prop_sort = sort(var_prop, 'descend');
    
    % See how much of the variance is explained by top chann prop threshold
    chan_thresh = ceil(numel(data_seg_temp.label) * chanprop);
    chan_var_prop(end+1) = sum(var_prop_sort(1:chan_thresh));
end

% Prepare variables for robust z-scores
good_trials_chan_var_prop = chan_var_prop(good_trials);
median_val = median(good_trials_chan_var_prop);
MAD_val    = median(abs(good_trials_chan_var_prop - median_val));

% Use the parameters from above to get robust z-scores of bad trials compared to good trials
bad_trials_chan_var_prop = chan_var_prop(bad_trials);
bad_trials_z_pow = 0.6745 * (bad_trials_chan_var_prop - median_val) / MAD_val;

% Identify bad trials NOT to reject (most of the variance explained by few chans)
if strcmp(savetrials, 'yes')
    safe_bad_trials_idx = find(bad_trials_z_pow > zchanpropvar);
    safe_bad_trials = bad_trials(safe_bad_trials_idx);
else 
    safe_bad_trials = [];
end

% Produce a stem plot of trial over median variance ratio 
if strcmp(badsegplot, 'yes')
    fig = figure('Visible', Show);                                   
    hold on;           

    % Create the stem plot
    stem(ratio_to_med, 'LineWidth', 1.5, 'Color', [0 0.45 0.74]);   

    % Outlier trials 
    idx_big = find(ratio_to_med > mthresh);                  

    % scatter the big points (filled for visibility)
    scatter(idx_big, ratio_to_med(idx_big), 100, ...    
            'MarkerEdgeColor', 'r', ...        % red border
            'MarkerFaceColor', 'none', ...     % hollow centre
            'LineWidth', 2);

    % scatter the big points for those will not be rejected
    scatter(safe_bad_trials, ratio_to_med(safe_bad_trials), 100, ...    
            'MarkerEdgeColor', '#1717bd', ...        
            'MarkerFaceColor', 'none', ...    
            'LineWidth', 2);
    
    xlabel('Sample index'); ylabel('Power');
    title('Amplitude variance for each trial / median trial variance');
    grid on;
    hold off;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'rmvtrialstemplot';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end
end 


% Produce a stem plot of high frq variance 
if strcmp(badsegplot, 'yes')
    fig = figure('Visible', Show);                                   
    hold on;           

    % Create the stem plot
    stem(z_pow, 'LineWidth', 1.5, 'Color', [0.1 0.75 0.65]);

    % Outlier trials 
    idx_big = find(abs(z_pow) > zthresh);                  

    % scatter the big points (filled for visibility)
    scatter(idx_big, z_pow(idx_big), 100, ...    
            'MarkerEdgeColor', 'r', ...        % red border
            'MarkerFaceColor', 'none', ...     % hollow centre
            'LineWidth', 1.5);

    % scatter the big points for those will not be rejected
    scatter(safe_bad_trials, z_pow(safe_bad_trials), 100, ...    
            'MarkerEdgeColor', '#1717bd', ...       
            'MarkerFaceColor', 'none', ...     % hollow centre
            'LineWidth', 1.5);
    
    xlabel('Sample index'); ylabel('Power');
    title('High Frq Band-Pass Filt Trial Variance (Robust Z-Score Threshold)');
    grid on;
    hold off;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'rmvhighfrqstemplot';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end
end 

% Remove safe bad trials from the ones about to get deleted
if strcmp(savetrials, 'yes')
    bad_trials = setdiff(bad_trials, safe_bad_trials);
    good_trials = setdiff(1:numel(data_seg_temp.trial), bad_trials);
end

% Segment the original (inputted) data if needed
if strcmp(datatype, 'rseeg')
    cfg_seg = [];
    cfg_seg.length  = seglength;   % segment (trial) length in seconds
    cfg_seg.overlap = 0;           % 0% overlap
    data_segmented = ft_redefinetrial(cfg_seg, data);
elseif strcmp(datatype, 'erp')
    data_segmented = data;
end


% Create a structure with `.artfctdef` field to specify bad trials (with
% sampleinfo)
%cfg_rej = [];
%cfg_rej.artfctdef.reject = 'partial';
%cfg_rej.artfctdef.bad.artifact = data_segmented.sampleinfo(bad_trials, :);

% Remove the bad trials from the data
%data_rej = ft_rejectartifact(cfg_rej, data_segmented); 

% We will instead keep good trials since this prevents errors with
% overlapping segments
cfg = [];
cfg.trials = good_trials;
data_rej = ft_selectdata(cfg, data_segmented);


% print out how many trials were removed
fprintf('Original trials: %d, After removal: %d\n', ...
        numel(data_seg_temp.trial), numel(data_rej.trial));
fprintf('Overall %.1f%% of trials were removed\n', ...
        round((1 - numel(data_rej.trial) / numel(data_seg_temp.trial))*100, 1));


% Print out individual plots if stated yes
if strcmp(indvbadsegplot, 'yes')
    for ii = bad_trials

        % Save current trial as a matrix
        X = data_segmented.trial{ii};
        X_atten = data_seg_temp.trial{ii};

        % Left plot
        fig = figure('Visible', Show);
        subplot(1, 2, 1);  % 1 row, 2 columns, position 1 (left)
        ft_quickplot3(X); title('Rejected Trial Number',ii)

        % Right plot
        subplot(1, 2, 2);  % Position 2 (right)
        ft_quickplot3(X_atten); title('Rejected Trial (Atten Blinks) Number:',ii)
        drawnow;

        % If plots are to be saved then save them
        if strcmp(saveplots, 'yes')
            cfg_sp = [];
            cfg_sp.fig = fig;
            cfg_sp.plotname = 'rmvtrial';
            cfg_sp.main = main;
            cfg_sp.skip = skip;
            cfg_sp.plotfolder = plotfolder;
            savehandlefig(cfg_sp)
        end     
    end
end

% Print out individual saved plots
if strcmp(indvbadsegplot, 'yes')
    for ii = safe_bad_trials

        % Save current trial as a matrix
        X = data_segmented.trial{ii};
        X_atten = data_seg_temp.trial{ii};

        % Left plot
        fig = figure('Visible', Show);
        subplot(1, 2, 1);  % 1 row, 2 columns, position 1 (left)
        ft_quickplot3(X); title('Saved Trial Number:',ii)

        % Right plot
        subplot(1, 2, 2);  % Position 2 (right)
        ft_quickplot3(X_atten); title('Saved Trial (Atten Blinks) Number:',ii)
        set(findall(gcf, 'Type', 'Line'), 'Color', [0 0 1]); drawnow;

        % If plots are to be saved then save them
        if strcmp(saveplots, 'yes')
            cfg_sp = [];
            cfg_sp.fig = fig;
            cfg_sp.plotname = 'savedtrial';
            cfg_sp.main = main;
            cfg_sp.skip = skip;
            cfg_sp.plotfolder = plotfolder;
            savehandlefig(cfg_sp)
        end     
    end
end


% Print out a good trial plot
if strcmp(onegoodplot, 'yes')
    
    % Obtain the trial closest to median var
    [~, good_plot_idx] = min(abs(ratio_to_med - 1));
    good_trial = data_segmented.trial{good_plot_idx};

    fig = figure('Visible', Show);
    X = good_trial;
    ft_quickplot3(X); title('Good Trial (Median Variance) Trial Number:',good_plot_idx)
    set(findall(gcf, 'Type', 'Line'), 'Color', [0 0.35 0]);
    drawnow;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'goodtrial';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end     

end



% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'rjctbadtrials';
    fun_name = 'ft_rejectbadsegments';

    % Prepare the stats structure
    stats = [];
    stats.trialsec = seglength;
    stats.initialtrials = numel(data_segmented.trial);
    stats.artiftrials = length(bad_trials);
    stats.remaintrials = stats.initialtrials - stats.artiftrials;
    stats.remainprop = round(stats.remaintrials / stats.initialtrials, 2, 'decimals');
    stats.successful = 'yes';

    % Generate the log for this function
    data_rej = ft_logstep(data_rej, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_rejectbadsegments log recorded\n');

end

% Update .intpmatrix if specified yes
if strcmp(intpmatrixupdt, 'yes')
    
    % Check to see if .intpmatrix already exists
    intpmatrix = data.cfg.preproc.intpmatrix;

    if isempty(intpmatrix)
        % segment the EEG data into trials
        intpmatrix = zeros(numel(data_rej.label), numel(data_rej.trial));
        data_rej.cfg.preproc.intpmatrix = intpmatrix;
        data_rej.cfg.preproc.labels = data_rej.label;
        return;
    end

    % Delete bad trials from .intpmatrix
    intpmatrix(:,bad_trials) = [];

    % Save this into the returned data
    data_rej.cfg.preproc.intpmatrix = intpmatrix;

end


end


