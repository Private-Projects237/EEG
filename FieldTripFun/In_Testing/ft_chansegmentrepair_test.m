function data = ft_chansegmentrepair_test(cfg, data)
%FT_CHANSEGMENTREPAIR_test Repair bad channels within a single trial.
% For each trial, specified thresholds are used to identify electrode pops,
% flatlined, and noisy channels. If present- they will be interpolated using
% ft_channelrepair(). Thus it is required to have both neighbour and `.elec`
% information available.
%
% WARNING: Data should already be segmented (contain trials)
%
% Usage:
% data_fixed = ft_chansegmentrepair(cfg, data)
%
% INPUT
% cfg.chansegmentrepair.thresh1 = 5 (default):
% cfg.chansegmentrepair.thresh2 = 0.05 (default);
% cfg.chansegmentrepair.thresh3 = 3 (default);
% cfg.chansegmentrepair.foilim = [30 100] (default);
% cfg.chansegmentrepair.log = 'no' (default);
%
% cfg.neighbours = neighbour structure from ft_prepare_neighbours **REQUIRED**
%
% OUTPUT:
% data = cleaned FieldTrip data structure (same format as input) with
% interpolated channels
%
% See also FT_CHANNELREPAIR, FT_REDEFINETRIAL, FT_PREPARE_NEIGHBOURS
% Save the original configuration
cfg_org = cfg;
% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'chansegmentrepair'});
% Safety check, neighbours structure needs to be present
if ~isfield(cfg.chansegmentrepair, 'neighbours')
    ft_error('cfg.neighbours is required – run ft_prepare_neighbours() first.');
end
% Save neighbours as an object
neighbours = cfg.chansegmentrepair.neighbours;
% Set up configuration defaults
cfg.chansegmentrepair = ft_getopt(cfg, 'chansegmentrepair', struct());
thresh1 = ft_getopt(cfg.chansegmentrepair, 'thresh1', 5);
thresh2 = ft_getopt(cfg.chansegmentrepair, 'thresh2', 0.05);
thresh3 = ft_getopt(cfg.chansegmentrepair, 'thresh3', 3);
foilim = ft_getopt(cfg.chansegmentrepair, 'foilim', [30 100]);
log = ft_getopt(cfg.chansegmentrepair, 'log', 'no');  % Fixed: was [30 100]


% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});
% Safety check, elec field needs to be present
if ~isfield(data, 'elec')
    ft_error('data.elec is required - run ft_read_sens() first;');
end
% Get the number of trials
trialNum = numel(data.trial);
chanIntp = zeros(1, trialNum);  % Preallocate as double array
% Create a for loop where each trial gets bad channels interpolated
for ii = 1:trialNum
    % Save trial information into an object
    x = data.trial{ii};
    % Delete columns where there is very high amplitude activity (represents blinks)
    x_centered = x - mean(x, 2); % Center each row
    z_x_row = zscore(x_centered, 0 , 2); % Calculate z-scores by row
    x_centered(:, any(z_x_row >= 3, 1)) = []; % Delete columns with high amplitude activity
    % For QC purposes we can plot
    % plot(x_centered')
    % Calculate variance from trial with 'blinks' or other large artifacts deleted
    chan_var = var(x_centered, [], 2);
   
    % Robust bad channel detector (ratio of variance over median variance)
    med_var = median(chan_var) + eps;
    ratio_to_med = chan_var / med_var;
    %sort(ratio_to_med)
    % Identify electrode pops and flatlined channels
    pop_chans = find(ratio_to_med > thresh1); % > 5× median
    flat_chans = find(ratio_to_med < thresh2); % < 5% of median
    
    % --- High-frequency noise: compute only on current trial ---
    tmpdata = struct();
    tmpdata.trial = {x};
    tmpdata.time = {data.time{ii}};
    tmpdata.label = data.label;
    tmpdata.fsample = data.fsample;
    
    cfg_freq = [];
    cfg_freq.method = 'mtmfft';
    cfg_freq.taper = 'hanning';
    cfg_freq.foilim = foilim; % sweat band
    cfg_freq.output = 'pow';
    cfg_freq.keeptrials = 'yes'; % keep each segment
    [~ ,freq] = evalc('ft_freqanalysis(cfg_freq, tmpdata)');
    
    % Identify high frequency noise
    pow_per_chan = squeeze(mean(freq.powspctrm, 3)); % channels x 1
    mean_pow_per_chan = pow_per_chan; % already averaged over freq
    z_pow = zscore(mean_pow_per_chan);
    noise_chans = find(z_pow > thresh3);
    
    % Combine the index of the bad channels (electrode pop, flat, noisy)
    % pop_chans = 14; flat_chans = 18; noise_chans = 19;
    % --- Fix: ensure all are row vectors before concatenation ---
    pop_chans = reshape(pop_chans, 1, []);
    flat_chans = reshape(flat_chans, 1, []);
    noise_chans = reshape(noise_chans, 1, []);
    bad_channs = unique([pop_chans, flat_chans, noise_chans]);
   
    if ~isempty(bad_channs)
        % Record number of bad channels found
        chanIntp(ii) = length(bad_channs);  % Store as double
        % Extract the labels that correspond with the bad channels
        artif.badchannel = data.label(bad_channs);
        % Create a structure to interpolate the channels
        cfg = [];
        cfg.badchannel = artif.badchannel;
        cfg.method = 'weighted';
        cfg.neighbours = neighbours;
        cfg.trials = ii; % Only interpolated channels in current trial
        % Create a field trip dataset with one segment fixed channels
        % The [~ , data] was used to shut up the function from producing a message in the command window
        [~ ,segment_fixed] = evalc('ft_channelrepair(cfg, data)'); % Creates one trial
        % Introduce the fixed segment into the original data
        data.trial{ii} = segment_fixed.trial{1};  % Fixed: {1} instead of {:}
        % Count each type
        npop = numel(pop_chans); nflat = numel(flat_chans); nnoise = numel(noise_chans);
        ntotal = numel(bad_channs);
        % Print the message
        fprintf('Trial number %d had %d channels interpolated:\n', ii, ntotal);
        fprintf('%d pop chans; %d flat chans; %d noisy chans\n', ...
            npop, nflat, nnoise);
    else
        chanIntp(ii) = 0;
    end
end

% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'intrptrialchans';
    fun_name = 'ft_chansegmentrepair';
    % Prepare the stats structure
    stats = [];
    stats.partlybadtrials = sum(chanIntp > 0);
    stats.totalchansint = sum(chanIntp);
    stats.chanxtrialdata = numel(data.label) * numel(data.trial);
    stats.propchanxtrialint = round(stats.totalchansint/stats.chanxtrialdata,2);
    stats.successful = 'yes';
    % Generate the log for this function
    data = ft_logstep(data, step_name, fun_name, cfg_org, stats);
    % Update that the log was recorded
    fprintf('ft_chansegmentrepair log recorded\n');
end
end