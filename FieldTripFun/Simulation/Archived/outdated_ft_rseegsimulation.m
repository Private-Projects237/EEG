% FT_RSEEGSIMULATION Simulate EEG data with 1/f noise and alpha peak
%
% Usage:
%   data = ft_rseegsimulation(cfg)
%
% Input:
%   cfg.nchan        = Number of channels (required)
%   cfg.triallength  = Trial length in seconds (required)
%   cfg.fsample      = Sampling frequency in Hz (required)
%   cfg.ntrials      = Number of trials (required)
%   cfg.alpha        = 1/f^alpha decay rate (default: 0.5)
%   ...
%
% Output:
%   data             = FieldTrip raw data structure

function [data] = ft_rseegsimulation(cfg)
    % Validate configuration
    cfg = ft_checkconfig(cfg, 'required', {'nchan', 'triallength', 'fsample', 'ntrials'});
    cfg = ft_checkconfig(cfg, 'renamed', {'smpfrq', 'fsample'; 'len', 'triallength'});
    cfg.alpha = ft_getopt(cfg, 'alpha', 0.5);
    cfg.noisescale = ft_getopt(cfg, 'noisescale', 0.2);
    cfg.peakamp = ft_getopt(cfg, 'peakamp', 0.1);
    cfg.peakfreq = ft_getopt(cfg, 'peakfreq', 10);
    cfg.peaksigma = ft_getopt(cfg, 'peaksigma', 1);
    cfg.chanvar = ft_getopt(cfg, 'chanvar', 0.1);
    cfg.trialvar = ft_getopt(cfg, 'trialvar', 0.1);

    % Calculate parameters
    nsamples = cfg.fsample * cfg.triallength; % Total samples per trial
    freqres = 1 / cfg.triallength; % Frequency resolution
    nyquist = cfg.fsample / 2; % Nyquist frequency
    nfreqs = nyquist / freqres; % Number of frequency components

    % Initialize data structure
    data = struct();
    data.label = cfg.label;
    data.trial = cell(1, cfg.ntrials);
    data.time = cell(1, cfg.ntrials);
    data.fsample = cfg.fsample;
    data.sampleinfo = zeros(cfg.ntrials, 2);

    % Generate time vector
    samp = 0:(nsamples - 1);
    time = samp / cfg.fsample;
    data.time = repmat({time}, 1, cfg.ntrials);

    % Channel-specific parameter scaling
    chanscale = 1 + cfg.chanvar * randn(5, cfg.nchan); % Fixed for all trials

    % Main generation loop
    begsample = 1;
    for trl = 1:cfg.ntrials
        % Trial-specific amplitude scaling
        trialscale = 1 + cfg.trialvar * randn(1);

        trialdata = zeros(cfg.nchan, nsamples);

        for chan = 1:cfg.nchan
            % Channel-specific parameters
            alpha = cfg.alpha * chanscale(1, chan);
            noisescale = cfg.noisescale * chanscale(2, chan);
            peakamp = cfg.peakamp * chanscale(3, chan);
            peakfreq = cfg.peakfreq * chanscale(4, chan);
            peaksigma = cfg.peaksigma * chanscale(5, chan);

            % Generate frequency components
            frq = freqres * (1:nfreqs);
            ampInv = noisescale ./ frq.^alpha;
            alphaPeak = peakamp * exp(-((frq - peakfreq).^2) / (2 * peaksigma));
            amp = (ampInv + alphaPeak) * trialscale;

            phases = 2 * pi * rand(1, nfreqs);

            % Vectorized sine wave generation
            sine_wav = amp' .* sin(2 * pi * frq' * time + phases');
            trialdata(chan, :) = sum(sine_wav, 1);
        end

        data.trial{trl} = trialdata;
        data.sampleinfo(trl, :) = [begsample, begsample + nsamples - 1];
        begsample = begsample + nsamples;
    end
end