function data = ft_addblinks(cfg, data)
% FT_ADDBLINKS Add realistic eye blink artifacts to specified EEG channels
%
% Use as:
%   data = ft_addblinks(cfg, data)
%
% Required cfg fields:
%   cfg.blinks.channels    = [1 2]     % Channel indices for Fp1, Fp2 (default: [1 2])
%   cfg.blinks.amplitude   = 5         % Peak amplitude in uV (default: 100)
%   cfg.blinks.duration    = 0.3       % Blink duration in seconds (default: 0.3)
%   cfg.blinks.shape       = 2         % t-distribution df (default: 2)
%   cfg.blinks.proportion  = 0.10      % Proportion of trials with blinks (default: 0.10)
%
% See also FT_CHECKCONFIG

% Set defaults
cfg = ft_checkconfig(cfg, 'required', {'blinks'});
blinks = cfg.blinks;

blinks.channels    = ft_getopt(blinks, 'channels', [1 2]);
blinks.amplitude   = ft_getopt(blinks, 'amplitude', 100);
blinks.duration    = ft_getopt(blinks, 'duration', 0.3);
blinks.shape       = ft_getopt(blinks, 'shape', 2);
blinks.proportion  = ft_getopt(blinks, 'proportion', 0.10);

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Extract parameters
chan_idx   = cfg.blinks.channels;
amplitude  = cfg.blinks.amplitude;
blink_dur  = cfg.blinks.duration;
shape_df   = cfg.blinks.shape;
prop_aff   = cfg.blinks.proportion;

n_trials = length(data.trial);
n_aff_trials = max(1, round(n_trials * prop_aff));  % At least 1 trial affected
aff_trial_idx = randsample(n_trials, n_aff_trials, false);

% Precompute normalized blink template
nsamp_blink = round(blink_dur * data.fsample);
t_blink = linspace(-2, 2, nsamp_blink);  % Symmetric around peak
blink_template = tpdf(t_blink, shape_df);
blink_template = blink_template / max(blink_template);  % Normalize to peak=1

% Add blinks to affected trials
for i = 1:numel(aff_trial_idx)
    i_trial = aff_trial_idx(i); % Explicitly assign scalar index
    trial_data = data.trial{i_trial};
    trial_len = size(trial_data, 2);
    
    % Random start position (ensure blink fits within trial)
    max_start = trial_len - nsamp_blink + 1;
    if max_start < 1
        fprintf('Skipping trial %d: too short\n', i_trial);
        continue;  % Skip if trial too short
    end
    blink_start = randi(max_start);
    
    % Add blink to each specified channel
    for i_chan = chan_idx
        if i_chan <= size(trial_data, 1)
            trial_data(i_chan, blink_start:(blink_start+nsamp_blink-1)) = ...
                trial_data(i_chan, blink_start:(blink_start+nsamp_blink-1)) + ...
                amplitude * blink_template;
        end
    end
    
    data.trial{i_trial} = trial_data;
end

end