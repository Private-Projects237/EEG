function data = ft_addchannoise(cfg, data)
% FT_ADDCHANNOISE  Add channel-specific artifacts (pop, flat, noisy, attenuated)
%   data = ft_addchannoise(cfg, data)
%
% cfg.chan.channels        = vector of channel indices
% cfg.chan.noisetype       = cell array, one per channel: 'pop'|'flat'|'noisy'|'attenuated'
% cfg.chan.noisemode       = 'full' | 'partial'          (default 'full')
% cfg.chan.noiseduration   = seconds (only for 'partial')
% cfg.chan.pop_amplitude   = µV
% cfg.chan.pop_freqrange   = [low high] Hz
% cfg.chan.flat_factor     = (kept for backward compatibility, ignored)
% cfg.chan.attenuated_factor = 0-1 scaling factor for *attenuated* type
% cfg.chan.noisy_amplitude = µV
% cfg.chan.noisy_freqrange = [low high] Hz
% cfg.chan.proportion      = 0-1 fraction of trials affected (default 1)

%% ---------- defaults ----------
cfg = ft_checkconfig(cfg, 'required', {'chan'});
chan = cfg.chan;

chan.channels        = ft_getopt(chan, 'channels',        [1 2]);
chan.noisetype       = ft_getopt(chan, 'noisetype',       repmat({'pop'},1,numel(chan.channels)));
chan.noisemode       = ft_getopt(chan, 'noisemode',       'full');
chan.noiseduration   = ft_getopt(chan, 'noiseduration',   3);
chan.pop_amplitude   = ft_getopt(chan, 'pop_amplitude',   200);
chan.pop_freqrange   = ft_getopt(chan, 'pop_freqrange',   [0.1 0.5]);
chan.flat_factor     = ft_getopt(chan, 'flat_factor',     0.01); % kept for old configs
chan.attenuated_factor = ft_getopt(chan, 'attenuated_factor', 0.01);
chan.noisy_amplitude = ft_getopt(chan, 'noisy_amplitude', 100);
chan.noisy_freqrange = ft_getopt(chan, 'noisy_freqrange', [20 100]);
chan.proportion      = ft_getopt(chan, 'proportion',      1.0);

%% ---------- validation ----------
data = ft_checkconfig(data, 'required', {'label','trial','time','fsample','sampleinfo'});

valid_noisetypes = {'pop','flat','noisy','attenuated'};
valid_noisemodes = {'full','partial'};
for k = 1:numel(chan.noisetype)
    if ~any(strcmp(chan.noisetype{k},valid_noisetypes))
        error('Invalid noisetype "%s" (channel %d)', chan.noisetype{k}, chan.channels(k));
    end
end
if numel(chan.noisetype) ~= numel(chan.channels)
    error('noisetype length must equal channels length');
end
if ~any(strcmp(chan.noisemode,valid_noisemodes))
    error('noisemode must be "full" or "partial"');
end

%% ---------- trial handling ----------
fs          = data.fsample;
nTrials     = numel(data.trial);
nAffected   = max(1, round(nTrials * chan.proportion));
affIdx      = randsample(nTrials, nAffected, false);   % trials that get noise

% length of each affected trial
trLen = cellfun(@(x) size(x,2), data.trial(affIdx));
totalSmp = sum(trLen);

% concatenate affected trials (channels × samples)
concat = zeros(numel(data.label), totalSmp);
cumSmp = [0 cumsum(trLen)];
for k = 1:nAffected
    tr = data.trial{affIdx(k)};
    concat(:, cumSmp(k)+1 : cumSmp(k+1)) = tr;
end

%% ---------- generate noise per channel ----------
for c = 1:numel(chan.channels)
    chIdx = chan.channels(c);
    if chIdx > size(concat,1), continue; end
    
    % ----- mask (full or partial) -----
    if strcmp(chan.noisemode,'partial')
        segSmp   = round(chan.noiseduration*fs);
        totalDur = totalSmp/fs;
        nSeg     = max(1, round(totalDur*0.25 / chan.noiseduration));
        maxStart = totalSmp - segSmp + 1;
        starts   = sort(randsample(maxStart, nSeg, false));
        mask     = false(1,totalSmp);
        for s = 1:nSeg
            mask(starts(s) : min(starts(s)+segSmp-1,totalSmp)) = true;
        end
    else
        mask = true(1,totalSmp);
    end
    
    % ----- time vector (used by several types) -----
    t = (0:totalSmp-1)/fs;
    
    % ----- noise generation -----
    switch lower(chan.noisetype{c})
        case 'pop'
            % random-walk + low-pass + amplitude modulation
            rw   = cumsum(randn(1,totalSmp)*0.1);
            [b,a]= butter(4, chan.pop_freqrange(2)/(fs/2), 'low');
            rw   = filtfilt(b,a,rw);
            rw   = rw / max(abs(rw)) * chan.pop_amplitude;
            mod  = sin(2*pi*mean(chan.pop_freqrange)*t + rand*2*pi);
            mod  = (mod+1)/2;
            noise = rw .* (0.5 + 0.5*mod);
            concat(chIdx,mask) = concat(chIdx,mask) + noise(mask);
            
        case 'flat'                         % *** REAL FLAT CHANNEL ***
            noise = zeros(1,totalSmp);
            % 1) thermal / ADC noise
            noise = noise + randn(1,totalSmp)*0.3;               % ~0.3 µV RMS
            % 2) very slow drift (random walk in µV)
            drift = 0.5 * cumsum(randn(1,totalSmp))/fs;
            drift = drift - mean(drift);
            noise = noise + drift;
            % 3) optional tiny 60 Hz line noise (30 % chance)
            if rand<0.3
                noise = noise + 0.5*sin(2*pi*60*t);
            end
            concat(chIdx,mask) = noise(mask);
            
        case 'attenuated'                   % low-gain but *correlated*
            concat(chIdx,mask) = concat(chIdx,mask) * chan.attenuated_factor;
            
        case 'noisy'
            freqs = linspace(chan.noisy_freqrange(1), chan.noisy_freqrange(2), 20);
            noise = zeros(1,totalSmp);
            for f = freqs
                noise = noise + sin(2*pi*f*t + rand*2*pi);
            end
            noise = noise / max(abs(noise)) * chan.noisy_amplitude;
            concat(chIdx,mask) = concat(chIdx,mask) + noise(mask);
    end
end

%% ---------- write back into original trials ----------
for k = 1:nAffected
    data.trial{affIdx(k)} = concat(:, cumSmp(k)+1 : cumSmp(k+1));
end
end