function data = ft_chansegmentrepair2(cfg, data)
%FT_CHANSEGMENTREPAIR2  Repair bad channels within a single trial. This
% function heavily relies on frequency information from delta, theta,
% alpha, and beta frequency bands. If a channel within a trial produces too
% much power (SDs above the mean using Robust Z-scores) compared to other channel x trial
% combinations, it will be interpolated. Interpolations will be done using
% ft_channelrepair(). Thus it is required to have both neighbour and `.elec`
% information available.
%
% WARNING: Data should already be segmented (contain trials)
%
% INPUT
%   cfg.chansegmentrepair2.deltafoilim =  [1 4] (rec); 
%   cfg.chansegmentrepair2.thetafoilim =  [4 8] (rec);
%   cfg.chansegmentrepair2.alphafoilim =  [8 12] (rec);
%   cfg.chansegmentrepair2.betafoilim  =  [13 30] (rec);
%   cfg.chansegmentrepair2.type        =  'all' or 'within'; how to calculate z-scores
%   cfg.chansegmentrepair2.zthresh     =  5 (default);
%   cfg.chansegmentrepair2.messages    = 'on' (default);
%   cfg.chansegmentrepair2.intpplot    = 'no' (default);
%   cfg.chansegmentrepair2.heatmap     = 'no' (default);
%   cfg.chansegmentrepair2.log         = 'no' (default);
%
%   cfg.chansegmentrepair2.neighbours  = neighbours
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (defaul);
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% OUTPUT
%   data_fixed = data 

% Save the original configuration
cfg_org = cfg; 

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'chansegmentrepair2'});

% Safety check, neighbours structure needs to be present 
if ~isfield(cfg.chansegmentrepair2, 'neighbours')
    ft_error('cfg.neighbours is required – run ft_prepare_neighbours() first.');
end

% Save neighbours as an object
neighbours   = cfg.chansegmentrepair2.neighbours; 

% Set up configuration defaults
cfg.chansegmentrepair2 = ft_getopt(cfg, 'chansegmentrepair2', struct());
deltafoilim      = ft_getopt(cfg.chansegmentrepair2, 'deltafoilim', []);
thetafoilim      = ft_getopt(cfg.chansegmentrepair2, 'thetafoilim', []);
alphafoilim      = ft_getopt(cfg.chansegmentrepair2, 'alphafoilim', []);
betafoilim       = ft_getopt(cfg.chansegmentrepair2, 'betafoilim', []);
type             = ft_getopt(cfg.chansegmentrepair2, 'type', 'within');
zthresh          = ft_getopt(cfg.chansegmentrepair2, 'zthresh', 4);
messages         = ft_getopt(cfg.chansegmentrepair2, 'messages', 'on');
intpplot         = ft_getopt(cfg.chansegmentrepair2, 'intpplot', 'no');
heatmap          = ft_getopt(cfg.chansegmentrepair2, 'heatmap', 'no');
log              = ft_getopt(cfg.chansegmentrepair2, 'log', 'no');

visibleplots = 'yes';
saveplots    = 'no';

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

% Safety check, elec field needs to be present 
if ~isfield(data, 'elec')
    ft_error('data.elec is required - run ft_read_sens() first;');
end

% Creata a frequency band matrix
FB = [deltafoilim; thetafoilim; alphafoilim; betafoilim];

%%%%%%%
%%%%%%%%%%%%% Part 1: Calculate Power Spectra For Input Data
%%%%%%%

% Create an object to store chann x trial power information for each FB
Bad_Chans_Trials_FB = [];

% Create a for loop that for each FB identifies problematic channels within each trial
for ii = 1:size(FB,1)
    % Compute power spectrum (method: mtmfft, taper: dpss)
    cfg = [];
    cfg.method     = 'mtmfft';
    cfg.taper      = 'hanning';
    cfg.foilim     = FB(ii,:);      % sweat band
    cfg.output     = 'pow';
    cfg.keeptrials = 'yes';       % keep each segment
    freq = ft_freqanalysis(cfg, data);
    
    % Average power within frequency bands (foilim)
    pow_per_trial_chan = squeeze(mean(freq.powspctrm, 3)); % trials x channel
    pow_per_chan_trial = pow_per_trial_chan'; % channel x trials

    % Robust z-scoring
    if strcmp(type, 'all')
        vector     = pow_per_chan_trial(:);
        med_val    = median(vector);
        mad_val    = median(abs(vector - med_val));
        z_pow      = 0.6745 * (vector - med_val) / mad_val;
        z_pow      = reshape(z_pow, size(pow_per_chan_trial));
        
    elseif strcmp(type, 'within')
        med_val    = median(pow_per_chan_trial, 2);                    % chan × 1
        mad_val    = median(abs(pow_per_chan_trial - med_val), 2);      % chan × 1
        z_pow      = 0.6745 * (pow_per_chan_trial - med_val) ./ mad_val; % broadcasting
    end
    
    Bad_Chans_Trials_FB{ii} = abs(z_pow) > zthresh;
    
    % Generate a heat map is specified
    if strcmp (heatmap, 'yes')
        % Produce heatmap of channels x trials
        fig = figure('Visible', Show);
        ft_quickplot2(pow_per_chan_trial); 
        title('Before Cleaning: Power Channel x Trial (Z-scores)');
        xlabel('Trials'); ylabel('Power'); set(gcf, 'Position', [300 400 600 500]);

        % If plots are to be saved then save them
        if strcmp(saveplots, 'yes')
            cfg_sp = [];
            cfg_sp.fig = fig;
            cfg_sp.plotname = 'origFBheatmap';
            cfg_sp.skip = skip;
            cfg_sp.plotfolder = plotfolder;
            savehandlefig(cfg_sp)
        end
    end

end

% Combine information from all frequency bands to create one matrix of bad chann x trials
SumMat = zeros(size(Bad_Chans_Trials_FB{1}));
for ii = 1:length(Bad_Chans_Trials_FB)
    SumMat = SumMat +  Bad_Chans_Trials_FB{ii};
end
onesMat = SumMat > 0;

%%%%%%%
%%%%%%%%%%%%% Part 2: Interpolate Channels Within Flagged Trials
%%%%%%%

% Find the trial num with at least one bad channel
badChanNum_perTrial = sum(onesMat,1);
badTrials = find(badChanNum_perTrial > 0);

% Create an object to store the number of bad channels interpolated for
% each flagged trials
badChanperTrial = [];

for ii = badTrials
        % Extract the labels that correspond with the bad channels
        badChans_idx = find(onesMat(:, ii));
        artif.badchannel = data.label(badChans_idx);

        % Save the bad channel
        badChanperTrial{end+1} = length(badChans_idx);

        % Create a structure to interpolate the channels
        cfg = [];
        cfg.badchannel     = artif.badchannel;
        cfg.method         = 'weighted';
        cfg.neighbours     = neighbours;
        cfg.trials         = ii; % Only interpolated channels in current trial

        % Create a field trip dataset with one segment fixed channels
        % The [~ , data] was used to shut up the function from producing a message in the command window
        [~ ,segment_fixed] = evalc('ft_channelrepair(cfg, data)'); % Creates one trial

        % Extract the full fixed trial 
        X = segment_fixed.trial{:};

        % Introduce the fixed segment into the original data
        data.trial{ii} = X;

        % Save a display of the channel interpolated
        badChannsNum = badChanNum_perTrial(ii);
        % Print the message
        if strcmp(messages, 'on')
            fprintf('Trial Num: %d - %d channels interpolated\n', ii, badChannsNum)
        end
end

%%%%%%%
%%%%%%%%%%%%% Part 3: Recalculate Power for Cleaned Segments
%%%%%%%

for ii = 1:size(FB,1)
    % Compute power spectrum (method: mtmfft, taper: dpss)
    cfg = [];
    cfg.method     = 'mtmfft';
    cfg.taper      = 'hanning';
    cfg.foilim     = FB(ii,:);      % sweat band
    cfg.output     = 'pow';
    cfg.keeptrials = 'yes';       % keep each segment
    freq = ft_freqanalysis(cfg, data);
    
    % Average power within frequency bands (foilim)
    pow_per_trial_chan = squeeze(mean(freq.powspctrm, 3)); % trials x channel
    pow_per_chan_trial = pow_per_trial_chan'; % channel x trials

    if strcmp (heatmap, 'yes')
        % Produce heatmap of channels x trials
        fig = figure('Visible', Show);
        ft_quickplot2(pow_per_chan_trial); 
        title('After Cleaning: Power Channel x Trial (Z-scores)');
        xlabel('Trials'); ylabel('Power'); set(gcf, 'Position', [900 400 600 500]);

        % If plots are to be saved then save them
        if strcmp(saveplots, 'yes')
            cfg_sp = [];
            cfg_sp.fig = fig;
            cfg_sp.plotname = 'cleanFBheatmap';
            cfg_sp.skip = skip;
            cfg_sp.plotfolder = plotfolder;
            savehandlefig(cfg_sp)
        end
    end

end


% Generate a plot of interpolated channels
if strcmp(intpplot, 'yes')
    % Plot the matrix of interpolated channels
    fig = figure('Visible', Show, 'Position', [100 100 800 600]);     
    imagesc(onesMat);

    % Add information about position and color
    set(gca, 'Position', [0.06 0.08 0.88 0.84]);   % forces the image to fill the figu
    colormap([1 1 1; 1 0 0]);   % white = good, red = interpolated
    colorbar('Ticks', [0 1], 'TickLabels', {'Good', 'Interpolated'});
    
    % Give some labels and a title
    xlabel('Trial number');
    ylabel('EEG Channel');
    title('Interpolated channels per trial');
    
    % Adds channel label information (very cool)
    axis ij                       % makes channel 1 appear at the top (highly recommended)
    set(gca, 'YTick', 1:numel(data.label), 'YTickLabel', data.label)

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'FBinterpchantrials';
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end
end

% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'intrptrialchans2';
    fun_name = 'ft_chansegmentrepair2';

    % Prepare the stats structure
    stats = [];
    stats.partlybadtrials = length(badTrials);
    stats.totalchansint = sum(cat(2, badChanperTrial{:}));
    stats.chanxtrialdata = numel(data.label) * numel(data.trial);
    stats.propchanxtrialint = round(stats.totalchansint/stats.chanxtrialdata,2);
    stats.successful = 'yes';

    % Generate the log for this function
    data = ft_logstep(data, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_chansegmentrepair2 log recorded\n');

end


end



 


