function data = ft_addlinenoise(cfg, data)
% FT_ADDLINENOISE Add realistic 50/60 Hz line noise + harmonics to EEG
%
% Use as:
%   data = ft_addlinenoise(cfg, data)
%
% Required cfg fields:
%   cfg.linenoise.freq       = 50 or 60          % Base frequency (Hz)
%   cfg.linenoise.amplitude  = 50                % Peak amplitude (μV)
%   cfg.linenoise.harmonics  = [100 150]         % Optional: harmonic freqs
%   cfg.linenoise.channels   = 'all'             % or [1:32]
%   cfg.linenoise.proportion = 1.0               % Proportion of trials
%
% Example:
%   cfg.linenoise.freq = 50;
%   cfg.linenoise.amplitude = 80;
%   cfg.linenoise.harmonics = [100 150 200];
%   data = ft_addlinenoise(cfg, data);
%
% See also FT_ADDMUSCLE, FT_ADDCHANNOISE

% === Set defaults and validate ===
cfg = ft_checkconfig(cfg, 'required', {'linenoise'});
ln = cfg.linenoise;

ln.freq       = ft_getopt(ln, 'freq', 50);
ln.amplitude  = ft_getopt(ln, 'amplitude', 50);
ln.harmonics  = ft_getopt(ln, 'harmonics', []);
ln.channels   = ft_getopt(ln, 'channels', 'all');
ln.proportion = ft_getopt(ln, 'proportion', 1.0);

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample'});

% Validate frequency
if ~ismember(ln.freq, [50, 60])
    error('cfg.linenoise.freq must be 50 or 60 Hz, got %g', ln.freq);
end

% Resolve channels
if ischar(ln.channels) && strcmp(ln.channels, 'all')
    chan_idx = 1:length(data.label);
else
    chan_idx = ln.channels;
end
if any(chan_idx > length(data.label))
    error('Channel index out of bounds');
end

% === Parameters ===
fs = data.fsample;
n_trials = length(data.trial);
n_affected = max(1, round(n_trials * ln.proportion));
affected_trials = randsample(n_trials, n_affected, false);

% Combine base + harmonics
freqs = [ln.freq, ln.harmonics];
n_freqs = length(freqs);

% Random phase for each frequency and trial (for realism)
phases = rand(n_freqs, n_affected) * 2 * pi;

% === Add line noise to affected trials ===
for i = 1:n_affected
    trl_idx = affected_trials(i);
    trial_data = data.trial{trl_idx};
    t = data.time{trl_idx};  % Time vector
    n_samples = length(t);
    
    % Initialize noise
    noise = zeros(length(chan_idx), n_samples);
    
    % Add each frequency component
    for f_idx = 1:n_freqs
        f = freqs(f_idx);
        phase = phases(f_idx, i);
        % Sinusoid: A * sin(2πft + φ)
        sinusoid = ln.amplitude * sin(2 * pi * f * t + phase);
        noise = noise + sinusoid;
    end
    
    % Add to selected channels
    trial_data(chan_idx, :) = trial_data(chan_idx, :) + noise;
    
    data.trial{trl_idx} = trial_data;
end

end