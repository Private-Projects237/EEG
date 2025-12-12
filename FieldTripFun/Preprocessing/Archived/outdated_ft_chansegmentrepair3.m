function data = ft_chansegmentrepair2(cfg, data)
%FT_CHANSEGMENTREPAIR3  Repair bad channels within a single trial. This
% function heavily relies on frequency information from delta, theta,
% alpha, and beta frequency bands. If a channel within a trial produces too
% much power (SDs above the mean) compared to other channel x trial
% combinations, it will be interpolated. Interpolations will be done using
% ft_channelrepair(). Thus it is required to have both neighbour and `.elec`
% information available.
%
% WARNING: Data should already be segmented (contain trials)
%
% INPUT
%   cfg.chansegmentrepair3.deltafoilim =  [1 4] (default); 
%   cfg.chansegmentrepair3.thetafoilim =  [4 8] (default);
%   cfg.chansegmentrepair3.alphafoilim =  [8 12] (default);
%   cfg.chansegmentrepair3.betafoilim  =  [13 30] (default);
%   cfg.chansegmentrepair3.zthresh     =  4 (default);
%   cfg.chansegmentrepair3.heatmap     = 'no' (default); 
%
%   cfg.chansegmentrepair3.neighbours  = neighbours
%
% OUTPUT
%   data_fixed = data 

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'chansegmentrepair3'});

% Safety check, neighbours structure needs to be present 
if ~isfield(cfg.chansegmentrepair3, 'neighbours')
    ft_error('cfg.neighbours is required – run ft_prepare_neighbours() first.');
end

% Save neighbours as an object
neighbours   = cfg.chansegmentrepair3.neighbours; 

% Set up configuration defaults
cfg.chansegmentrepair3 = ft_getopt(cfg, 'chansegmentrepair3', struct());
deltafoilim      = ft_getopt(cfg.chansegmentrepair3, 'deltafoilim', [1 4]);
thetafoilim      = ft_getopt(cfg.chansegmentrepair3, 'thetafoilim', [4 8]);
alphafoilim      = ft_getopt(cfg.chansegmentrepair3, 'alphafoilim', [8 12]);
betafoilim       = ft_getopt(cfg.chansegmentrepair3, 'betafoilim', [13 30]);
zthresh          = ft_getopt(cfg.chansegmentrepair3, 'zthresh', 4);
heatmap          = ft_getopt(cfg.chansegmentrepair3, 'heatmap', 'no');

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

    % Convert the matrix into z-scores
    vector = pow_per_chan_trial(:);
    z_vector = zscore(vector);
    z_pow = reshape(z_vector, size(pow_per_chan_trial));
    Bad_Chans_Trials_FB{ii} = z_pow > zthresh; 

    if strcmp (heatmap, 'yes')
        % Produce heatmap of channels x trials
        ft_quickplot2(pow_per_chan_trial); title('Power Channel x Trial (Z-scores)');
        xlabel('Trials'); ylabel('Power'); set(gcf, 'Position', [300 400 600 500]);
    end

end

% Combine information from all frequency bands to create one matrix of bad chann x trials
SumMat = Bad_Chans_Trials_FB{1} + Bad_Chans_Trials_FB{2} + Bad_Chans_Trials_FB{3} + Bad_Chans_Trials_FB{4};
onesMat = SumMat > 0;

%%%%%%%
%%%%%%%%%%%%% Part 2: Interpolate Channels Within Flagged Trials
%%%%%%%

% Find the trial num with at least one bad channel
badChanNum_perTrial = sum(onesMat,1);
badTrials = find(badChanNum_perTrial > 0);

for ii = badTrials
        % Extract the labels that correspond with the bad channels
        badChans_idx = find(onesMat(:, ii));
        artif.badchannel = data.label(badChans_idx);

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
        fprintf('Trial Num: %d - %d channels interpolated\n', ii, badChannsNum)
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
        ft_quickplot2(pow_per_chan_trial); title('Power Channel x Trial (Z-scores)');
        xlabel('Trials'); ylabel('Power'); set(gcf, 'Position', [900 400 600 500]);
    end

end


end



 


