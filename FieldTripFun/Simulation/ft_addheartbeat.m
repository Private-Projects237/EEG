function data = ft_addheartbeat(cfg, data)
% FT_ADDHEARTBEAT Add synchronized cardiac (ECG) artifact across all trials
%
% Heartbeats are *globally synchronized* — same timing in every trial
% Only *within-beat jitter* (biological variation)
%
% cfg.heartbeat.channels   = [1 2 7 8];   % Fp1, Fp2, F7, F8
% cfg.heartbeat.rate       = 72;          % BPM
% cfg.heartbeat.amplitude  = 45;          % µV
% cfg.heartbeat.jitter     = 0.05;        % ±5% timing jitter (per beat)

% === Config ===
cfg = ft_checkconfig(cfg, 'required', {'heartbeat'});
h   = cfg.heartbeat;

h.channels   = ft_getopt(h, 'channels', [1 2]);
h.rate       = ft_getopt(h, 'rate', 72);
h.amplitude  = ft_getopt(h, 'amplitude', 45);
h.jitter     = ft_getopt(h, 'jitter', 0.05);  % ±5%

% Validate
data = ft_checkconfig(data, 'required', {'label','trial','time','fsample'});
fs = data.fsample;

% === GLOBAL HEARTBEAT CLOCK ===
beat_interval = 60 / h.rate;  % seconds per beat

% Find total recording time
total_start = min(cellfun(@(x) x(1), data.time));
total_end   = max(cellfun(@(x) x(end), data.time));
total_dur   = total_end - total_start;

% Generate *global* beat times with per-beat jitter
n_beats = round(total_dur / beat_interval);
ideal_times = (0:n_beats-1) * beat_interval + total_start;
beat_times = ideal_times + randn(size(ideal_times)) * beat_interval * h.jitter;
beat_times = beat_times(:);  % column vector

% === ECG Pulse Shape ===
pulse_width = 0.1;  % sec
pulse_samples = round(pulse_width * fs * 2);
t_pulse = linspace(-pulse_width, pulse_width, pulse_samples);
pulse = exp(-((t_pulse-0.03)/0.02).^2) - 0.3*exp(-((t_pulse+0.02)/0.04).^2);
pulse = pulse / max(abs(pulse)) * h.amplitude;
pulse = pulse(:)';  % row vector

fprintf('Adding synchronized heartbeat (%.1f BPM) to %d channels\n', h.rate, length(h.channels));

% === Add pulses to each trial using GLOBAL timing ===
for t = 1:length(data.trial)
    trial_data = data.trial{t};
    t_vec = data.time{t};
    trial_start = t_vec(1);
    trial_end = t_vec(end);
    
    % Find beats that fall within this trial
    in_trial = beat_times >= trial_start & beat_times <= trial_end;
    trial_beats = beat_times(in_trial);
    
    for bt = trial_beats'
        center_samp = round((bt - trial_start) * fs) + 1;
        start_samp = max(1, center_samp - round(pulse_width*fs));
        end_samp = min(size(trial_data,2), center_samp + round(pulse_width*fs) - 1);
        idx = start_samp:end_samp;
        pulse_idx = 1:(end_samp-start_samp+1);
        
        pulse_block = repmat(pulse(pulse_idx), length(h.channels), 1);
        trial_data(h.channels, idx) = trial_data(h.channels, idx) + pulse_block;
    end
    
    data.trial{t} = trial_data;
end

fprintf('Done! %d synchronized heartbeats added\n', length(beat_times));
end