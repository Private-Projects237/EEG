function [data] = ft_rseegsimulation(cfg)
% ft_rseegsimulation Simulate EEG data with 1/f noise and alpha peak (correlated version)
%
% Usage:
%   data = ft_rseegsimulation(cfg)
%
% Input:
%   cfg.nchan       = Number of channels (required)
%   cfg.triallength = Trial length in seconds (required)
%   cfg.fsample     = Sampling frequency in Hz (required)
%   cfg.ntrials     = Number of trials (required)
%   cfg.alpha       = 1/f^alpha decay rate (default: 0.5)
%   cfg.noisescale  = scaling of the 1/f component (default: 0.2)
%   cfg.peakamp     = amplitude of the alpha peak (default: 0.1)
%   cfg.peakfreq    = centre frequency of the alpha peak (default: 10)
%   cfg.peaksigma   = width of the alpha peak (default: 1)
%   cfg.chanvar     = channel-to-channel random scaling (default: 0.1)
%   cfg.trialvar    = trial-to-trial random scaling (default: 0.1)
%
%   % CORRELATION CONTROL
%   cfg.globalweight = proportion of shared global source (0-1, default: 0.6)
%   cfg.localamp     = amplitude of independent local source per channel (default: 0.5)
%   cfg.sensornoise  = white sensor noise amplitude (default: 0.2)
%
% Output:
%   data = FieldTrip raw data structure

% Validate configuration
cfg = ft_checkconfig(cfg, 'required', {'nchan', 'triallength', 'fsample', 'ntrials'});
cfg = ft_checkconfig(cfg, 'renamed', {'smpfrq', 'fsample'; 'len', 'triallength'});
cfg.alpha       = ft_getopt(cfg, 'alpha',       0.5);
cfg.noisescale  = ft_getopt(cfg, 'noisescale',  0.2);
cfg.peakamp     = ft_getopt(cfg, 'peakamp',     0.1);
cfg.peakfreq    = ft_getopt(cfg, 'peakfreq',    10);
cfg.peaksigma   = ft_getopt(cfg, 'peaksigma',   1);
cfg.chanvar     = ft_getopt(cfg, 'chanvar',     0.1);
cfg.trialvar    = ft_getopt(cfg, 'trialvar',    0.1);

% Correlation control
cfg.globalweight = ft_getopt(cfg, 'globalweight', 0.6);
cfg.localamp     = ft_getopt(cfg, 'localamp',     0.5);
cfg.sensornoise  = ft_getopt(cfg, 'sensornoise',  0.2);

% Calculate parameters
nsamples = round(cfg.fsample * cfg.triallength);
freqres  = 1 / cfg.triallength;
nyquist  = cfg.fsample / 2;
nfreqs   = floor(nyquist / freqres);

% Time vector
time = (0:nsamples-1) / cfg.fsample;

% Frequency vector
frq = freqres * (1:nfreqs);

% Spectral shape (1/f + alpha peak) — same for all trials
ampInv  = cfg.noisescale ./ (frq .^ cfg.alpha);
alphaPk = cfg.peakamp * exp(-((frq - cfg.peakfreq).^2) / (2 * cfg.peaksigma^2));
ampShape = ampInv + alphaPk;

% Channel-specific local scaling (fixed across trials)
localScale = cfg.localamp * (1 + cfg.chanvar * randn(cfg.nchan, 1));

% Initialize data structure
data = struct();
data.label      = cfg.label(:);
data.trial      = cell(1, cfg.ntrials);
data.time       = cell(1, cfg.ntrials);
data.fsample    = cfg.fsample;
data.sampleinfo = zeros(cfg.ntrials, 2);

% === TRIAL LOOP: NEW PHASE, NEW NOISE, SAME CORRELATION ===
begsample = 1;
for trl = 1:cfg.ntrials
    
    % --- GLOBAL source (shared across channels, new per trial) ---
    phGlob = 2*pi*rand(1, nfreqs);
    sineGlob = sin(2*pi*frq'*time + phGlob');
    globWav = sum(ampShape' .* sineGlob, 1);  % 1 x nsamples

    % --- LOCAL source (independent per channel, new per trial) ---
    localWav = zeros(cfg.nchan, nsamples);
    for chan = 1:cfg.nchan
        phLocal = 2*pi*rand(1, nfreqs);
        sineLocal = sin(2*pi*frq'*time + phLocal');
        localWav(chan, :) = localScale(chan) * sum(ampShape' .* sineLocal, 1);
    end

    % --- Mix global + local ---
    mixed = cfg.globalweight * repmat(globWav, cfg.nchan, 1) + (1 - cfg.globalweight) * localWav;

    % --- Add sensor noise (new per trial) ---
    noise = cfg.sensornoise * randn(cfg.nchan, nsamples);
    trialdata = mixed + noise;

    % --- Trial-specific amplitude scaling ---
    trialscale = 1 + cfg.trialvar * randn(1);
    data.trial{trl} = trialdata * trialscale;

    % --- Time and sample info ---
    data.time{trl} = time;
    data.sampleinfo(trl,:) = [begsample, begsample + nsamples - 1];
    begsample = begsample + nsamples;
end

end