function [sweat_boundaries] = detect_sweat_artifact(cfg, data)
% DETECT_SWEAT_ARTIFACT Uses band-pass filter of low frequencies [0.25 2]
% to strengthed sweat artifacts and weaken real signal. In this state (time
% domain), we use robust z-scores (MAD) to identify sample numbers that may
% be sweat artifacts (could also be blinks)- we then use number of affected
% channels and duration information to identidy sample number beginning and
% start points (boundaries) of suspect sweat contamination. 
%
% INPUT
%   cfg.detectsweat.zthresh       = 5.5 (default); Robust z-score (MAD) amplitude required to
%       be considered sweat artifacts
%   cfg.detectsweat.minchan       = 3 (default); Trial must have these number of channels
%       with activity larger than zthresh to be considered a sweat artifact 
%   cfg.detectsweat.mindur_sec    = 3 (default); seconds of artifact present to be
%       considered a sweat artifact
%   cfg.detectsweat.buffer_sec    = 6 (default); increases boundary to get
%       a longer recording (the value is halved for the start of the sweat
%       artifact)
%
% OUTPUT
%   [sweat_boundaries] sample numbers of each suspected sweat artifact (if any)


% Check configuration for correct parameters
cfg = ft_checkconfig(cfg, 'required', {'detectsweat'});

% Set up configuration defaults
cfg.detectsweat = ft_getopt(cfg, 'detectsweat', struct());
zthresh         = ft_getopt(cfg.detectsweat, 'zthresh', 5.5);
minchan         = ft_getopt(cfg.detectsweat, 'minchan', 3);
mindur_sec      = ft_getopt(cfg.detectsweat, 'mindur_sec', 3);
buffer_sec      = ft_getopt(cfg.detectsweat, 'buffer_sec', 6);

% Force data to be continuous if not
if numel(data.trial) > 1
    cfg_cont = [];
    cfg_cont.continuous = 'yes';
    data = ft_redefinetrial(cfg_cont, data);
end

% Part 1: Low frq band-pass filter + Hilbert envelope (absolute values time domain)
cfg = [];
cfg.bpfilter   = 'yes';
cfg.bpfreq     = [0.25  2];
cfg.bpfilttype = 'firws';
cfg.bpfiltdir  = 'twopass';
tmp = ft_preprocessing(cfg, data);

cfg = []; cfg.hilbert = 'abs';
lf_env = ft_preprocessing(cfg, tmp);

% Part 2: Calculate robust z-scores (MAD) of low frq amplitudes (time domain)
pow = lf_env.trial{1};
z   = zeros(size(pow));
for ch = 1:size(pow,1)
    x = pow(ch,:);
    med = median(x);
    MAD = median(abs(x-med));
    z(ch,:) = 0.6745 * (x - med) / (MAD + eps);
end


% Part 3: Identify samples that exceed the zthresh and have min required channels
multi_exceed = sum(abs(z) > zthresh, 1) >= minchan;

% Create a function that returns boundaries in samples
zero_to_one = [];
one_to_zero = [];

for ii = 1:(length(multi_exceed) - 1)
    % Tracker sample number of when a 0 turns into a 1
    if multi_exceed(ii) == 0 && multi_exceed(ii+1) == 1
        zero_to_one(end+1) = ii + 1;

    elseif multi_exceed(ii) == 1 && multi_exceed(ii+1) == 0
        one_to_zero(end+1) = ii + 1;
    end
end

% Get the number of starts and stops from the data
n_starts = length(zero_to_one);
n_ends   = length(one_to_zero);

% Most common case: equal number of starts and ends
if n_starts == n_ends
    noise_segments = [zero_to_one(:), one_to_zero(:)-1];   % -1 because transition is at ii+1

% One more start than end → noise still present at the end
elseif n_starts == n_ends + 1
    noise_segments = [zero_to_one(1:end-1)', one_to_zero(:)-1;
                      zero_to_one(end),     length(multi_exceed)];  % last segment goes to end

% One more end than start → something weird at the very beginning (rare, but handle it)
elseif n_ends == n_starts + 1
    noise_segments = [1,                one_to_zero(1)-1;
                      zero_to_one(:),   one_to_zero(2:end)-1];
end

% Obtain number of samples that a sweat artifact MUST have (not to confuse with blinks)
min_samples = round(mindur_sec * data.fsample);

% Remove rows that are too short
duration = noise_segments(:,2) - noise_segments(:,1) + 1;
noise_segments(duration <= min_samples, :) = [];

% Take the boundary of each segment and add buffer
sweat_boundaries = noise_segments;
sweat_boundaries(:,1) = noise_segments(:,1) - (1 * data.fsample);
sweat_boundaries(:,2) = noise_segments(:,2) + (buffer_sec * data.fsample);

% Make sure samples are within boundary of the recording
sweat_boundaries((sweat_boundaries < 1)) = 1;
sweat_boundaries((sweat_boundaries > length(multi_exceed))) = length(multi_exceed)-1;

% Merge overlapping or adjacent intervals
merged = [];
if ~isempty(sweat_boundaries)
    current = sweat_boundaries(1, :);
    for k = 2:size(sweat_boundaries,1)
        if sweat_boundaries(k,1) <= current(2) + 1   % overlapping or touching
            current(2) = max(current(2), sweat_boundaries(k,2));
        else
            merged = [merged; current];
            current = sweat_boundaries(k,:);
        end
    end
    merged = [merged; current];  % don't forget the last one
end

% Update sweaet boundaries with non overlapping segments
sweat_boundaries = merged;

end
