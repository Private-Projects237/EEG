function data = ft_adddrift(cfg, data)
% FT_ADDDRIFT Add realistic cumulative DC drift across trials
%
% DC drift: slow linear baseline shift that *accumulates* over time
% Common in long recordings due to electrode, skin, or amplifier changes
%
% Use as:
%   data = ft_adddrift(cfg, data)
%
% INPUT:
%   cfg.drift.slope       = 100       % the slope given to each channel
%   cfg.drift.polarity    = 'mixed'  % 'up', 'down', 'mixed'
%   cfg.drift.channels    = 'all'    % or [1:32]
%   cfg.drift.slope_var   = 50        % Some variability added to the slope
%   cfg.drift.k           = 2        % Skewness of gamma distribution (slope variability)
%
% OUTPUT
%   data_drift = the same dataset with each channel having a DC Offset

% Default configuration
cfg = ft_checkconfig(cfg, 'required', {'drift'});
d = cfg.drift;

cfg.slope      = ft_getopt(d, 'slope', 100);      % base slope in µV/s
cfg.slope_var  = ft_getopt(d, 'slope_var', 30);  % std dev of slope variation
cfg.k          = ft_getopt(d, 'k', 2);  % std dev of slope variation
cfg.polarity   = ft_getopt(d, 'polarity', 'mixed');
cfg.channels   = ft_getopt(d, 'channels', 'all');

% Validate input data
data = ft_checkconfig(data, 'required', {'label','trial','time','fsample'});
if ~ismember(cfg.polarity, {'up','down','mixed'})
    error('cfg.drift.polarity must be ''up'', ''down'', or ''mixed''');
end

% Short names
base_slope  = cfg.slope;
slope_var   = cfg.slope_var;
polarity    = cfg.polarity;
channels    = cfg.channels;
k           = cfg.k;
fs          = data.fsample;


% === 1. SELECT CHANNELS ===
if ischar(channels) && strcmp(channels, 'all')
    chan_idx = 1:length(data.label);
else
    chan_idx = channels(:)';  % row vector
end
n_chan = length(chan_idx);

% === 2. ASSIGN PER-CHANNEL SLOPE & POLARITY (once!) ===
% Base slope + small deviation (gamma) 
theta = slope_var / k;
gamma_deviations = gamrnd(k, theta, 1, n_chan);
channel_slopes   = base_slope + gamma_deviations;

% Polarity: +1 (up), -1 (down), or mixed
if strcmp(polarity, 'up')
    pol = ones(1, n_chan);
elseif strcmp(polarity, 'down')
    pol = -ones(1, n_chan);
else % 'mixed'
    p_up = 0.85;  % probability of upward drift
    pol = 2*(rand(1, n_chan) < p_up) - 1;
end

% Final signed slope per channel (consistent across all trials)
signed_slopes = pol .* channel_slopes;  % [µV/s] per channel

% === 3. CUMULATIVE OFFSET TRACKER ===
cumulative_offset = zeros(1, n_chan);  % starts at 0 µV

% === 4. LOOP OVER TRIALS ===
for t = 1:length(data.trial)
    trial_data = data.trial{t};
    t_vec      = data.time{t};           % time vector in seconds
    n_samples  = length(t_vec);
    
    % Time relative to trial start
    t_rel = t_vec - t_vec(1);  % [0, duration]
    
    % Drift ramp for THIS trial: signed_slope * time
    % Shape: [n_chan x n_samples]
    drift_ramp = signed_slopes' * t_rel;  % outer product: each chan has own slope
    
    % Add: original signal + current drift ramp + previous cumulative offset
    trial_data(chan_idx, :) = trial_data(chan_idx, :) ...
        + drift_ramp ...
        + cumulative_offset';  % broadcast offset to all samples
    
    % === UPDATE CUMULATIVE OFFSET FOR NEXT TRIAL ===
    % End of this trial = start of next
    trial_duration = t_rel(end);
    cumulative_offset = cumulative_offset + signed_slopes * trial_duration;
    
    % Save back
    data.trial{t} = trial_data;
end


end