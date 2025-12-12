function data = ft_addmuscle(cfg, data)
% FT_ADDMUSCLE Add realistic muscle (EMG) artifacts to contiguous EEG channels
%
% Use as:
%   data = ft_addmuscle(cfg, data)
%
% Required cfg fields:
%   cfg.muscle.channels = [5:16] % Vector of *adjacent* channel indices
%   cfg.muscle.freqrange = [20 100] % Frequency band for muscle noise (Hz)
%   cfg.muscle.amplitude = 150 % Peak amplitude of burst (µV)
%   cfg.muscle.duration = [1 4] % Duration range of each burst (seconds)
%   cfg.muscle.proportion = 0.15 % Proportion of trials with muscle artifact
%   cfg.muscle.nbursts = [1 3] % Number of bursts per affected trial
%
% See also FT_CHECKCONFIG, FT_ADDBLINKS, FT_ADDCHANNOISE

% === Set defaults and validate ===
cfg = ft_checkconfig(cfg, 'required', {'muscle'});
muscle = cfg.muscle;
muscle.channels    = ft_getopt(muscle, 'channels',    []);
muscle.freqrange   = ft_getopt(muscle, 'freqrange',   [20 100]);
muscle.amplitude   = ft_getopt(muscle, 'amplitude',   150);
muscle.duration    = ft_getopt(muscle, 'duration',    [1 4]);
muscle.proportion  = ft_getopt(muscle, 'proportion',  0.15);
muscle.nbursts     = ft_getopt(muscle, 'nbursts',     [1 3]);

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample'});

% === Validate channel adjacency ===
if isempty(muscle.channels)
    error('cfg.muscle.channels must be specified');
end
if ~isvector(muscle.channels) || length(muscle.channels) < 2
    error('cfg.muscle.channels must contain at least 2 channels');
end

% Allow one or more *contiguous* blocks  (e.g. [1:10] or [1:10,16:18])
if any(diff(muscle.channels) <= 0)
    error('cfg.muscle.channels must be strictly increasing');
end
blockStart = [1, find(diff(muscle.channels) ~= 1)+1];
for b = 1:numel(blockStart)
    s = blockStart(b);
    if b == numel(blockStart)
        e = numel(muscle.channels);
    else
        e = blockStart(b+1) - 1;
    end
    if e - s < 1
        error('Each contiguous block must have >=2 channels');
    end
end

% Validate channel bounds
nchan = numel(data.label);
if any(muscle.channels > nchan) || any(muscle.channels < 1)
    error('Channel index out of bounds (data has %d channels)', nchan);
end

% === Parameters ===
fs        = data.fsample;
n_trials  = numel(data.trial);
n_affected = max(1, round(n_trials * muscle.proportion));
affected_trials = randsample(n_trials, n_affected, false);

freq_low = muscle.freqrange(1);
freq_high = muscle.freqrange(2);
dur_min  = muscle.duration(1);
dur_max  = muscle.duration(2);
nb_min   = muscle.nbursts(1);
nb_max   = muscle.nbursts(2);
amp      = muscle.amplitude;

% Design bandpass filter (4th-order Butterworth)
nyq = fs/2;
[b,a] = butter(4, [freq_low freq_high]/nyq, 'bandpass');

% === Add muscle bursts to affected trials ===
for i = 1:n_affected
    trl_idx    = affected_trials(i);
    trial_data = data.trial{trl_idx};
    trial_len  = size(trial_data,2);
    time_vec   = data.time{trl_idx};
    
    % Number of bursts in this trial
    n_bursts = randi([nb_min, nb_max]);
    
    for b = 1:n_bursts
        % Random duration and start time
        burst_dur     = dur_min + rand*(dur_max-dur_min);
        burst_samples = round(burst_dur*fs);
        max_start     = trial_len - burst_samples + 1;
        if max_start < 1, continue; end
        
        start_samp = randi(max_start);
        end_samp   = start_samp + burst_samples - 1;
        
        % Generate white noise
        noise_raw = randn(1, burst_samples);
        
        % Bandpass filter to muscle band
        noise_filt = filtfilt(b,a,noise_raw);
        
        % Scale to desired amplitude
        noise_filt = noise_filt / std(noise_filt) * (amp/3); % ~3σ = peak
        
        % Add to all muscle channels
        trial_data(muscle.channels, start_samp:end_samp) = ...
            trial_data(muscle.channels, start_samp:end_samp) + noise_filt;
    end
    
    data.trial{trl_idx} = trial_data;
end
end