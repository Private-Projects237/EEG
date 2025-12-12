function data_segrepaired = ft_chansegmentrepair(cfg, data)
%FT_CHANSEGMENTREPAIR  Repair bad channels within a single trial. We use
% information from all channel x trials in the data to identify artifact
% channels based on having high variances past a robust z-score threshold.
% We can specify what frequencies we are most interested in (band-pass)- 
% brain or not  and then calculate robust z-scores in the time domain to 
% identify bad channels x trials to interpolate. 
%
% WARNING: Data should already be segmented (contain trials)
%
% Usage:
%   data_fixed = ft_chansegmentrepair(cfg, data)
%
% INPUT
%   cfg.chansegmentrepair.zthresh1        = 5 (default); Robust z-score threshold for general data
%   cfg.chansegmentrepair.zthresh2        = 5 (default); Robust z score threshold band-pass filtered data
%   cfg.chansegmentrepair.regfrqbp      = [30 140] (default); band-pass filter
%   cfg.chansegmentrepair.type           = 'all' or 'within'; how to calculate z-scores
%   cfg.chansegmentrepair.log            = 'no' (default);
%   cfg.chansegmentrepair.intpmatrixupdt = 'no' (default); creates/updates intpmatrix field
%   cfg.chansegmentrepair.intmatrixplot  = 'no' (default); Shows a plot of int channels by trials
%   cfg.chansegmentrepair.afterintplot   = 'no' (default); Shows the EEG data after interpolations
%   cfg.chansegmentrepair.messages       = 'on' (default); Shows each channel x trial interpolation
%
%   cfg.neighbours    = neighbour structure from ft_prepare_neighbours **REQUIRED**
%
% INPUT (Deleting bad trials)
%   cfg.chansegmentrepair.rmvtrials =  'yes' (recommended);
%   cfg.chansegmentrepair.badchanprop = 0.20 (recommended);
%   cfg.chansegmentrepair.indvbadsegplot   = 'no' (default): Creates individual plots of bad trials
%
% INPUT (Special - Recommended for Eyes Open)
%   cfg.chansegmentrepair.peakprotection = 'no' (default); Attenuates blink
%       amplitudes for specified channels when calculating electrode pop
%       variance.
%   cfg.chansegmentrepair.blinkchans     = {}; cell array (ex: {'Fp1', 'Fp2'}
%   cfg.chansegmentrepair.attenblnkplot  = 'no' (default);
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% OUTPUT:
%   data    = cleaned FieldTrip data structure (same format as input) with
%                   interpolated channels
%
%   See also FT_CHANNELREPAIR, FT_REDEFINETRIAL, FT_PREPARE_NEIGHBOURS

% Save the original configuration
cfg_org = cfg; 

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'chansegmentrepair'});

% Safety check, neighbours structure needs to be present 
if ~isfield(cfg.chansegmentrepair, 'neighbours')
    ft_error('cfg.neighbours is required – run ft_prepare_neighbours() first.');
end

% Save neighbours as an object
neighbours   = cfg.chansegmentrepair.neighbours; 

% Set up configuration defaults
cfg.chansegmentrepair = ft_getopt(cfg, 'chansegmentrepair', struct());
zthresh1       = ft_getopt(cfg.chansegmentrepair, 'zthresh1', 5);
zthresh2       = ft_getopt(cfg.chansegmentrepair, 'zthresh2', 5);
regfrqbp       = ft_getopt(cfg.chansegmentrepair, 'regfrqbp', [30 140]);
type           = ft_getopt(cfg.chansegmentrepair, 'type', 'all');
intmatrixplot  = ft_getopt(cfg.chansegmentrepair, 'intmatrixplot', 'no');
afterintplot   = ft_getopt(cfg.chansegmentrepair, 'afterintplot', 'no');
messages       = ft_getopt(cfg.chansegmentrepair, 'messages', 'on');
log            = ft_getopt(cfg.chansegmentrepair, 'log', 'no');
intpmatrixupdt = ft_getopt(cfg.chansegmentrepair, 'intpmatrixupdt', 'no');

rmvtrials      = ft_getopt(cfg.chansegmentrepair, 'rmvtrials', 'no');
badchanprop    = ft_getopt(cfg.chansegmentrepair, 'badchanprop', []);
indvbadsegplot = ft_getopt(cfg.chansegmentrepair, 'indvbadsegplot', 'no');

peakprotection      = ft_getopt(cfg.chansegmentrepair, 'peakprotection', 'no');
blinkchans          = ft_getopt(cfg.chansegmentrepair, 'blinkchans', []);
attenblnkplot       = ft_getopt(cfg.chansegmentrepair, 'attenblnkplot', 'no');

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

% Safety check, elec field needs to be present 
if ~isfield(data, 'elec')
    ft_error('data.elec is required - run ft_read_sens() first;');
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


%%%%%%%%%%%%% CALCULATING REGULAR CHANN x TRIAL VARIANCE (ALL OR WITHIN) %%%%%%%%%%%%%%

% Create a structure to calculate robust-zscores
cfg_rz = [];
cfg_rz.robustzmatrix.segmentdat   = 'no' ;
cfg_rz.robustzmatrix.segseclength = [];
cfg_rz.robustzmatrix.type = type;
robust_z1 = ft_robustzmatrix(cfg_rz, temp_dat);

%%%%%%%%% CALCULATING HIGH PASS FILT CHANN X TRIAL VARIANCE (ALL OR WITHIN) %%%%%%%%%%%

% band-pass filter high frequency information
cfg_filt = [];
cfg_filt.bpfilter   = 'yes';
cfg_filt.bpfreq     = regfrqbp;
cfg_filt.bpfiltord  = 4;          
cfg_filt.padding    = 2;           
cfg_filt.padtype    = 'mirror';   
dat_filt = ft_preprocessing(cfg_filt, temp_dat);

% Create a structure to calculate robust-zscores
cfg_rz = [];
cfg_rz.robustzmatrix.segmentdat   = 'no' ;
cfg_rz.robustzmatrix.segseclength = [];
cfg_rz.robustzmatrix.type = type;
robust_z2 = ft_robustzmatrix(cfg_rz, dat_filt);

%%%%%%%%%% IDENTIFYING BAD TRIALS AND BAD CHANNELS WITHIN TRIALS %%%%%%%%%%%%%%

% Flag bad channel-trial pairs
bad_chan_trial1 = double(robust_z1 >= zthresh1); % Ones and zeros
bad_chan_trial2 = double(robust_z2 >= zthresh2); 
bad_chan_trial2(bad_chan_trial2 == 1) = 2; % Twos and zeroes
bad_chan_trial_comb = bad_chan_trial1 + bad_chan_trial2; % Three, two, ones, and zeroes (plotting)
bad_chan_trial = bad_chan_trial_comb >= 1; % Logical (Used for deleting/interpolating)

% Number of bad channels that represent a bad trial
bad_chan_thresh = ceil(badchanprop * numel(data.label));

% Identify any bad trials in the data
bad_chan_per_trial = sum(bad_chan_trial, 1);
bad_trials = find(bad_chan_per_trial >= bad_chan_thresh);


% Create a matrix showing which channels in what trials were interpolated/deleted
if strcmp(intmatrixplot, 'yes')

    % Left plot
    fig = figure('Visible', Show); 
    subplot(1, 2, 1);  % 1 row, 2 columns, position 1 (left)
    ft_quickplot2(robust_z1);
    xlabel('Trial number');
    ylabel('EEG Channel');
    title('Robust Z Channel x Trial (General)');

    % Right plot
    subplot(1, 2, 2);  % Position 2 (right)
    ft_quickplot2(robust_z2);
    xlabel('Trial number');
    ylabel('EEG Channel');
    title('Robust Z Channel x Trial (Band-Pass)')
    drawnow;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'chantrialsrobustz';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

    % Convert all values of bad_trials into 0.5 (plotting purposes)
    display_matrix = bad_chan_trial_comb;
    display_matrix(:, bad_trials) = 4;

    % To test;
    % any(display_matrix == 3, 'all')
    
    % Generate the plot
    fig = figure('Visible','on', 'Position',[100 100 1000 600], 'Color','w');
    imagesc(display_matrix);
    axis image;
    
    % Set the colors for different type of channel x trials status
    colormap(fig, [
        1.000 1.000 1.000;   % 0 = No problems (White)
        0.850 0.000 0.000;   % 1 = Bad in general (Red)
        0.180 0.510 0.800;   % 3 = Bad in high Frq (Blue)
        1.000 0.600 0.000;   % 3 = Bad in both (Orange)
        0.500 0.500 0.500]); % 4 = Bad trials (Grey)
    
    % grey = 0.5 0.5 0.5
    % Force exact integer mapping (no interpolation)
    caxis([-0.5 4.5]);

    colorbar('Location', 'southoutside', ...
        'Ticks',[0 1 2 3 4], ...
        'TickLabels',{'Good','General Bad','Band Pass Filt Bad','Bad in Both','Bad Trial'});

    % Axes and title information
    xlabel('Trial number', 'FontSize', 12);
    ylabel('EEG Channel', 'FontSize', 12);
    set(gca, 'Position', [0.08 0.18 0.85 0.75]);   
    title(sprintf('Interpolated channels per trial (General + Band-Pass Filt: %g-%g Hz)', regfrqbp(1), regfrqbp(2)));
    set(gca, 'YTick', 1:numel(data.label), 'YTickLabel', data.label, 'FontSize', 9);

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'chantrials2intpmatrix';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end
end


%%%%%%%%%%%%%%%% (OPTIONAL) DELETING BAD SEGMENTS %%%%%%%%%%%%%%%%%%%%%

% Print out individual plots if stated yes
if strcmp(indvbadsegplot, 'yes') && strcmp(rmvtrials, 'yes')
    for ii = bad_trials

        % Save current trial as a matrix
        X = data.trial{ii};
        X_atten = temp_dat.trial{ii};

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

% Marking segments for deletion if specified
if strcmp(rmvtrials, 'yes') && numel(data.trial) ~= length(bad_trials)

    % Delete the bad segments
    cfg_rej = [];
    cfg_rej.artfctdef.reject = 'complete';
    cfg_rej.artfctdef.bad.artifact = data.sampleinfo(bad_trials, :);
    
    % Remove the bad trials from the data
    data = ft_rejectartifact(cfg_rej, data); 

    % Update matrix by deleting columns that represented bad trials
    bad_chan_trial(:,bad_trials) = [];

end

% Save data (with or without deleted segments) as a new object
data_segrepaired = data;

% Create a for loop to interpolate bad channels within trials
if sum(bad_chan_trial(:)) > 0 && numel(data.trial) ~= length(bad_trials)
    nTrials = size(bad_chan_trial,2);

    for ii = 1:nTrials
        % Skip if there is no bad channel in the trial
        current_Trial = bad_chan_trial(:,ii);
        if sum(current_Trial) == 0; continue; end 

        % Extract artifact channel labels
        artif.badchannel = data.label(current_Trial);

        % Create a structure to interpolate the channels
        cfg_repair = [];
        cfg_repair.badchannel     = artif.badchannel;
        cfg_repair.method         = 'weighted';
        cfg_repair.neighbours     = neighbours;
        cfg_repair.trials         = ii; % Only interpolated channels in current trial

        % Create a field trip dataset with one segment fixed channels
        % The [~ , data] was used to shut up the function from producing a message in the command window
        [~ , segment_fixed] = evalc('ft_channelrepair(cfg_repair, data)'); % Creates one trial

        % Introduce the fixed segment into the original data (data_segrepaired)
        data_segrepaired.trial{ii} = segment_fixed.trial{:};

        % Count each type
        ntotal = sum(current_Trial);

        % Print the message
        if strcmp(messages, 'on')
            fprintf('Trial number %d had %d channels interpolated:\n', ii, ntotal);
        end

    end

else
    warning('No Channels Needed Repair')
end


% Generate a plot of the EEG data by channel (Before Interpolation)
if strcmp(afterintplot, 'yes') && numel(data.trial) ~= length(bad_trials)
    % Convert the FieldTrip data into a single matrix
    X = cat(2, data.trial{:});
    
    % Center and offset for stacked plot
    X_c = X - mean(X, 2);                              % remove mean per channel
    offset = 14 * std(X(:));                           % vertical spacing
    channel_offset = (0:size(X,1)-1)' * offset;
    stacked_data = X_c + channel_offset;
    
    % Plot - all channels in the same dark gray
    good_color = [0.3 0.3 0.3];
    
    fig = figure('Visible', Show, 'Position', [100 100 1000 800]);
    hold on;
    plot(stacked_data', 'Color', good_color, 'LineWidth', 1);  % <-- transposed
    hold off;
    
    % Labels and formatting
    title('EEG Data Before Bad Channels Within Trials Interpolated')
    xlabel('Sample Number');
    ylabel('Amplitude (stacked)');
    
    yticks(channel_offset);
    yticklabels(data.label);
    set(gca, 'FontSize', 8);
    
    axis('ij');   % channels increase downward like in classic EEG plots
    grid on;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'afterintchantrials';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

end

% Generate a plot of the EEG data by channel (After Interpolation)
if strcmp(afterintplot, 'yes') && numel(data.trial) ~= length(bad_trials)
    % Convert the FieldTrip data into a single matrix
    X = cat(2, data_segrepaired.trial{:});
    
    % Center and offset for stacked plot
    X_c = X - mean(X, 2);                              % remove mean per channel
    offset = 14 * std(X(:));                           % vertical spacing
    channel_offset = (0:size(X,1)-1)' * offset;
    stacked_data = X_c + channel_offset;
    
    % Plot - all channels in the same dark gray
    good_color = [0.3 0.3 0.3];
    
    fig = figure('Visible', Show, 'Position', [100 100 1000 800]);
    hold on;
    plot(stacked_data', 'Color', good_color, 'LineWidth', 1);  % <-- transposed
    hold off;
    
    % Labels and formatting
    title('EEG Data After Bad Channels Within Trials Interpolated')
    xlabel('Sample Number');
    ylabel('Amplitude (stacked)');
    
    yticks(channel_offset);
    yticklabels(data_segrepaired.label);
    set(gca, 'FontSize', 8);
    
    axis('ij');   % channels increase downward like in classic EEG plots
    grid on;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'afterintchantrials';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

end

% Create variables that give information about the interpolation
partlybadTrials = sum(bad_chan_trial, 1) > 1;

% If there were no good trials left run this
if numel(data.trial) == length(bad_trials)
    data_segrepaired.trial = [];
end

% if log is needed generate this output
if strcmp(log, 'yes')

    % Prepare function name and what it does
    step_name = 'intrptrialchans';
    fun_name = 'ft_chansegmentrepair';

    % Prepare the stats structure
    stats = [];
    stats.type = type;
    stats.rmvtrials = rmvtrials;
    stats.initialtrials = numel(temp_dat.trial);
    stats.artiftrials = length(bad_trials);
    stats.remaintrials = stats.initialtrials - stats.artiftrials;
    stats.remainprop = round(stats.remaintrials / stats.initialtrials, 2, 'decimals');
    stats.partlybadtrials = sum(partlybadTrials);
    stats.totalchansint = sum(bad_chan_trial(:));
    stats.chanxtrialdata = numel(data_segrepaired.label) * numel(data_segrepaired.trial);
    stats.propchanxtrialint = round(stats.totalchansint/stats.chanxtrialdata,2);
    stats.successful = 'yes';

    % Generate the log for this function
    data_segrepaired = ft_logstep(data_segrepaired, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_chansegmentrepair log recorded\n');
end


% Update .intpmatrix if specified yes
if strcmp(intpmatrixupdt, 'yes') 
    
    % Check to see if .intpmatrix already exists
    intpmatrix = data_segrepaired.cfg.preproc.intpmatrix; % Keep as data_segrepaited not data
    if isempty(intpmatrix)
        % segment the EEG data into trials
        intpmatrix = zeros(numel(data_segrepaired.label), numel(data_segrepaired.trial));
        data_segrepaired.cfg.preproc.intpmatrix = intpmatrix;
        data_segrepaired.cfg.preproc.labels = data_segrepaired.label;
        return;
    end

    % Delete bad trials from .intpmatrix
    if strcmp(rmvtrials, 'yes')
        intpmatrix(:, bad_trials) = [];
    end

    % Introduce channel x trial interpolations
    if size(intpmatrix,1) == size(bad_chan_trial, 1) && ~isempty(intpmatrix)
        intpmatrix = intpmatrix + bad_chan_trial;
        intpmatrix = intpmatrix >= 1;

    elseif size(intpmatrix,1) > size(bad_chan_trial, 1)
        labels = data_segrepaired.cfg.preproc.labels;
        intersecting_chans = ismember(labels, data_segrepaired.label);
        intpmatrix(intersecting_chans,:) = intpmatrix(intersecting_chans,:) + bad_chan_trial;
        intpmatrix = intpmatrix >= 1;

    elseif ~isempty(intpmatrix)
        error('Inconsistent row sizes between intpmatrix and inputted data')
    end

    % Save this into the returned data
    data_segrepaired.cfg.preproc.intpmatrix = intpmatrix;

end


end

