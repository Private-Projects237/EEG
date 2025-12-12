function data = ft_addsaccades(cfg, data)
% FT_ADDSACCADES Add realistic eye saccade artifacts to specified EEG channels
%
% Use as:
%   data = ft_addsaccades(cfg, data)
%
% Required cfg fields:
%   cfg.sacc.channels    = [1 2]     % Channel indices for Fp1, Fp2 (default: [1 2])
%   cfg.sacc.amplitude   = 300        % (legacy) peak amplitude for BOTH directions
%   cfg.sacc.amplitude_pos = 300      % peak amplitude of right-ward saccades (µV)
%   cfg.sacc.amplitude_neg = 300      % peak amplitude of left-ward saccades (µV)
%   cfg.sacc.direction_prob = 0.5    % prob. of right-ward (rest = left-ward)
%   cfg.sacc.duration    = 0.15      % Saccade duration in seconds (default: 0.15)
%   cfg.sacc.slope       = 0.1       % Plateau slope factor (default: 0.1)
%   cfg.sacc.proportion  = 0.10      % Proportion of trial groups with saccades (default: 0.10)
%
% See also FT_CHECKCONFIG

% Set defaults
cfg = ft_checkconfig(cfg, 'required', {'sacc'});
sacc = cfg.sacc;

sacc.channels       = ft_getopt(sacc, 'channels', [1 2]);
sacc.duration       = ft_getopt(sacc, 'duration', 0.15);
sacc.slope          = ft_getopt(sacc, 'slope', 0.1);
sacc.proportion     = ft_getopt(sacc, 'proportion', 0.10);

% Amplitude handling (backward compatible)
amp_legacy          = ft_getopt(sacc, 'amplitude', []);
amp_pos             = ft_getopt(sacc, 'amplitude_pos', amp_legacy);
amp_neg             = ft_getopt(sacc, 'amplitude_neg', amp_legacy);
if isempty(amp_pos) && isempty(amp_neg)
    amp_pos = 300; amp_neg = 300;
elseif isempty(amp_pos)
    amp_pos = amp_neg;
elseif isempty(amp_neg)
    amp_neg = amp_pos;
end
sacc.direction_prob = ft_getopt(sacc, 'direction_prob', 0.5);

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Extract parameters
chan_idx   = sacc.channels;
sacc_dur   = sacc.duration;
slope_fac  = sacc.slope;
prop_aff   = sacc.proportion;
prob_right = sacc.direction_prob;

n_trials = length(data.trial);
n_groups = max(1, round(n_trials * prop_aff / 3));  % Number of 3-trial groups
n_trials_per_group = 3;

% Ensure there are enough trials for groups
if n_trials < n_trials_per_group
    error('Not enough trials (%d) to form %d-trial groups', n_trials, n_trials_per_group);
end

% Select starting indices for groups (ensure groups don't overlap)
max_start_idx = n_trials - n_trials_per_group + 1;
group_start_idx = randsample(max_start_idx, n_groups, false);

% Precompute unit-amplitude saccade template (positive direction)
nsamp_sacc = round(sacc_dur * data.fsample);
rise_samples = round(nsamp_sacc * 0.2);  % 20% for onset
fall_samples = round(nsamp_sacc * 0.2);  % 20% for offset
plat_samples = nsamp_sacc - rise_samples - fall_samples;  % Remaining for plateau

% Create time vector for saccade
t_sacc = linspace(0, 1, nsamp_sacc);
template_pos = zeros(1, nsamp_sacc);

% Onset: linear ramp up
template_pos(1:rise_samples) = linspace(0, 1, rise_samples);

% Plateau: slight linear slope
plat_idx = rise_samples + 1 : rise_samples + plat_samples;
template_pos(plat_idx) = 1 + slope_fac * linspace(0, 1, plat_samples);

% Offset: linear ramp down
fall_idx = rise_samples + plat_samples + 1 : nsamp_sacc;
template_pos(fall_idx) = linspace(1, 0, fall_samples);

% Normalize to peak=1
template_pos = template_pos / max(template_pos);

% Add saccades to affected trial groups
for i_group = 1:n_groups
    start_trial = group_start_idx(i_group);
    group_trials = start_trial : start_trial + n_trials_per_group - 1;
    
    % Determine total samples across group
    trial_lengths = cellfun(@(x) size(x,2), data.trial(group_trials));
    total_samples = sum(trial_lengths);
    
    if total_samples < nsamp_sacc
        fprintf('Warning: Group %d skipped (too short: %d samples < %d)\n', ...
            i_group, total_samples, nsamp_sacc);
        continue;
    end
    
    % Random start position across group
    max_start = total_samples - nsamp_sacc + 1;
    sacc_start = randi(max_start);
    
    % Decide direction: right (positive) or left (negative)
    is_right = rand < prob_right;
    amp      = is_right * amp_pos + ~is_right * amp_neg;
    template = is_right * template_pos + ~is_right * (-template_pos);
    
    % Map saccade to trials
    cum_samples = [0 cumsum(trial_lengths)];
    for i = 1:length(group_trials)
        i_trial = group_trials(i);
        trial_data = data.trial{i_trial};
        
        % Find samples of saccade that fall in this trial
        trial_start = cum_samples(i) + 1;
        trial_end = cum_samples(i+1);
        sacc_idx = max(1, sacc_start - trial_start + 1) : ...
                   min(trial_lengths(i), sacc_start + nsamp_sacc - trial_start);
        global_sacc_idx = max(1, trial_start - sacc_start + 1) : ...
                          min(nsamp_sacc, trial_end - sacc_start + 1);
        
        if isempty(sacc_idx) || isempty(global_sacc_idx)
            continue;
        end
        
        % Add saccade to valid channels
        for i_chan = chan_idx
            if i_chan <= size(trial_data, 1)
                trial_data(i_chan, sacc_idx) = trial_data(i_chan, sacc_idx) + ...
                    amp * template(global_sacc_idx);
            end
        end
        
        data.trial{i_trial} = trial_data;
    end
end

end