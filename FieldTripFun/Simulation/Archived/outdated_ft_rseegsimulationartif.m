% FT_RSEEGSIMULATIONARTIF Simulate EEG data with 1/f noise, alpha peak, and optional artifacts
%
% Usage:
%   data = ft_rseegsimulationartif(cfg)
%
% Input:
%   cfg.nchan        = Number of channels (required)
%   cfg.triallength  = Trial length in seconds (required)
%   cfg.fsample      = Sampling frequency in Hz (required)
%   cfg.ntrials      = Number of trials (required)
%   cfg.alpha        = 1/f^alpha decay rate (default: 0.5)
%   cfg.noisescale   = Scaling factor for 1/f noise (default: 0.2)
%   cfg.peakamp      = Scaling factor for alpha peak (default: 0.1)
%   cfg.peakfreq     = Center frequency of alpha peak (Hz, default: 10)
%   cfg.peaksigma    = Sigma for alpha peak (default: 1)
%   cfg.chanvar      = Variability across channels (default: 0.1)
%   cfg.trialvar     = Variability across trials (default: 0.1)
%   cfg.artifacts    = Struct specifying artifacts to include (optional)
%       .noisy_channel      = Struct for fully noisy channel
%           .enable         = Boolean to enable (default: false)
%           .channels       = Channel indices
%           .amplitude      = Noise amplitude scale (default: 100)
%           .type           = 'white' or 'bandlimited' (default: 'white')
%           .freq_range     = Frequency range for bandlimited noise
%       .partial_noisy      = Struct for partially noisy channel
%           .enable         = Boolean to enable (default: false)
%           .channels       = Channel indices
%           .trials         = Proportion (0–1) of affected trials per channel
%           .amplitude      = Noise amplitude scale (default: 100)
%           .type           = 'white' or 'bandlimited' (default: 'white')
%           .freq_range     = Frequency range for bandlimited noise
%       .muscle             = Struct for muscle artifacts
%           .enable         = Boolean to enable (default: false)
%           .channels       = Channel indices
%           .freq_range     = Frequency range (e.g., [20, 100])
%           .amplitude      = Noise amplitude scale (default: 100)
%           .duration       = Duration of each burst (default: 0.5)
%           .frequency      = Number of bursts per trial (default: 3)
%       .blink              = Struct for eye blinks
%           .enable         = Boolean to enable (default: false)
%           .channels       = Channel indices (e.g., [1, 2] for Fp1, Fp2)
%           .amplitude      = Peak amplitude (default: 100)
%           .duration       = Width of each blink (default: 0.3)
%           .frequency      = Number of blinks per trial (default: 2)
%           .shape          = t-distribution degrees of freedom (default: 2)
%       .eye_movement       = Struct for horizontal eye movements (saccades) - PLATEAUS
%           .enable         = Boolean to enable (default: false)
%           .channels       = Channel indices (e.g., [11, 12] for F7, F8)
%           .amplitude      = Plateau amplitude (default: 10)
%           .duration       = Plateau duration (default: 0.2)
%           .frequency      = Number of saccades per trial (default: 3)
%       .sweat              = Struct for sweat artifacts (non-linear drift)
%           .enable         = Boolean to enable (default: false)
%           .channels       = Channel indices
%           .amplitude      = Peak amplitude of quadratic trend (default: 5)
%           .trials         = Proportion (0–1) of affected trials
%       .heart              = Struct for heart (ECG) artifacts
%           .enable         = Boolean to enable (default: false)
%           .channels       = Channel indices
%           .amplitude      = Peak amplitude of QRS pulse (default: 5)
%           .frequency      = Heart rate in Hz (default: 1 = 60 bpm)
%           .duration       = Width of QRS pulse (default: 0.1)
%       .line_noise         = Struct for line noise (50/60 Hz)
%           .enable         = Boolean to enable (default: false)
%           .channels       = Channel indices
%           .amplitude      = Amplitude of sinusoidal noise (default: 2)
%           .frequency      = Line frequency in Hz (default: 60)
%       .electrode_pop      = Struct for electrode pop artifacts
%           .enable         = Boolean to enable (default: false)
%           .channels       = Channel indices
%           .amplitude      = Amplitude of pop spikes (default: 50)
%           .frequency      = Number of pops per trial (default: 1)
%           .duration       = Width of each pop (default: 0.2)
%
% Output:
%   data             = FieldTrip raw data structure

function [data] = ft_rseegsimulationartif(cfg)
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

    % Initialize artifact defaults
    cfg.artifacts = ft_getopt(cfg, 'artifacts', struct());
    cfg.artifacts.noisy_channel = ft_getopt(cfg.artifacts, 'noisy_channel', struct('enable', false, 'amplitude', 100));
    cfg.artifacts.partial_noisy = ft_getopt(cfg.artifacts, 'partial_noisy', struct('enable', false, 'amplitude', 100));
    cfg.artifacts.muscle = ft_getopt(cfg.artifacts, 'muscle', struct('enable', false, 'amplitude', 100, 'duration', 0.5, 'frequency', 3));
    cfg.artifacts.blink = ft_getopt(cfg.artifacts, 'blink', struct('enable', false, 'amplitude', 100, 'frequency', 2));
    cfg.artifacts.eye_movement = ft_getopt(cfg.artifacts, 'eye_movement', struct('enable', false, 'amplitude', 10, 'duration', 0.2, 'frequency', 3));
    cfg.artifacts.sweat = ft_getopt(cfg.artifacts, 'sweat', struct('enable', false, 'amplitude', 5, 'trials', 0.5));
    cfg.artifacts.heart = ft_getopt(cfg.artifacts, 'heart', struct('enable', false, 'amplitude', 5, 'frequency', 1, 'duration', 0.1));
    cfg.artifacts.line_noise = ft_getopt(cfg.artifacts, 'line_noise', struct('enable', false, 'amplitude', 2, 'frequency', 60));
    cfg.artifacts.electrode_pop = ft_getopt(cfg.artifacts, 'electrode_pop', struct('enable', false, 'amplitude', 50, 'frequency', 1, 'duration', 0.2));

    % Calculate parameters
    nsamples = cfg.fsample * cfg.triallength;
    freqres = 1 / cfg.triallength;
    nyquist = cfg.fsample / 2;
    nfreqs = nyquist / freqres;
    frq = freqres * (1:nfreqs);

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
    chanscale = 1 + cfg.chanvar * randn(5, cfg.nchan);

    % Main generation loop
    begsample = 1;
    for trl = 1:cfg.ntrials
        trialscale = 1 + cfg.trialvar * randn(1);
        trialdata = zeros(cfg.nchan, nsamples);

        % Generate clean EEG data
        for chan = 1:cfg.nchan
            alpha = cfg.alpha * chanscale(1, chan);
            noisescale = cfg.noisescale * chanscale(2, chan);
            peakamp = cfg.peakamp * chanscale(3, chan);
            peakfreq = cfg.peakfreq * chanscale(4, chan);
            peaksigma = cfg.peaksigma * chanscale(5, chan);

            ampInv = noisescale ./ frq.^alpha;
            alphaPeak = peakamp * exp(-((frq - peakfreq).^2) / (2 * peaksigma));
            amp = (ampInv + alphaPeak) * trialscale;
            phases = 2 * pi * rand(1, nfreqs);

            sine_wav = amp' .* sin(2 * pi * frq' * time + phases');
            trialdata(chan, :) = sum(sine_wav, 1);
        end

        % Apply artifacts if enabled
        if cfg.artifacts.noisy_channel.enable
            nc = cfg.artifacts.noisy_channel;
            nc_channels = ft_getopt(nc, 'channels', []);
            nc_amplitude = ft_getopt(nc, 'amplitude', 100);
            nc_type = ft_getopt(nc, 'type', 'white');
            nc_freq_range = ft_getopt(nc, 'freq_range', [20, 100]);

            for chan = nc_channels
                if strcmp(nc_type, 'white')
                    noise = nc_amplitude * randn(1, nsamples);
                else
                    noise = bandlimited_noise(nsamples, cfg.fsample, nc_freq_range, nc_amplitude);
                end
                trialdata(chan, :) = trialdata(chan, :) + noise;
            end
        end

        if cfg.artifacts.partial_noisy.enable
            pn = cfg.artifacts.partial_noisy;
            pn_channels = ft_getopt(pn, 'channels', []);
            pn_amplitude = ft_getopt(pn, 'amplitude', 100);
            pn_type = ft_getopt(pn, 'type', 'white');
            pn_freq_range = ft_getopt(pn, 'freq_range', [20, 100]);

            for chan = pn_channels
                chan_trials = select_partial_trials(cfg, pn);
                if ismember(trl, chan_trials)
                    if strcmp(pn_type, 'white')
                        noise = pn_amplitude * randn(1, nsamples);
                    else
                        noise = bandlimited_noise(nsamples, cfg.fsample, pn_freq_range, pn_amplitude);
                    end
                    trialdata(chan, :) = trialdata(chan, :) + noise;
                end
            end
        end

        if cfg.artifacts.muscle.enable
            m = cfg.artifacts.muscle;
            m_channels = ft_getopt(m, 'channels', []);
            m_freq_range = ft_getopt(m, 'freq_range', [20, 100]);
            m_amplitude = ft_getopt(m, 'amplitude', 100);
            m_duration = ft_getopt(m, 'duration', 0.5);
            m_frequency = ft_getopt(m, 'frequency', 3);

            nsamp_burst = round(m_duration * cfg.fsample);
            for i = 1:round(m_frequency)
                start = randi([1, nsamples - nsamp_burst + 1]);
                noise = bandlimited_noise(nsamp_burst, cfg.fsample, m_freq_range, m_amplitude);
                for chan = m_channels
                    trialdata(chan, start:(start + nsamp_burst - 1)) = ...
                        trialdata(chan, start:(start + nsamp_burst - 1)) + noise;
                end
            end
        end

        if cfg.artifacts.blink.enable
            b = cfg.artifacts.blink;
            b_channels = ft_getopt(b, 'channels', [1, 2]);
            b_amplitude = ft_getopt(b, 'amplitude', 100);
            b_duration = ft_getopt(b, 'duration', 0.3);
            b_frequency = ft_getopt(b, 'frequency', 2);
            b_shape = ft_getopt(b, 'shape', 2);

            nsamp_blink = round(b_duration * cfg.fsample);
            t = linspace(-3, 3, nsamp_blink);
            blink_shape = b_amplitude * tpdf(t, b_shape) / max(tpdf(t, b_shape));
            for i = 1:round(b_frequency)
                start = randi([1, nsamples - nsamp_blink + 1]);
                for chan = b_channels
                    trialdata(chan, start:(start + nsamp_blink - 1)) = ...
                        trialdata(chan, start:(start + nsamp_blink - 1)) + blink_shape;
                end
            end
        end

        % HORIZONTAL EYE MOVEMENTS (SACCADES) - PLATEAUS
        if cfg.artifacts.eye_movement.enable
            em = cfg.artifacts.eye_movement;
            em_channels = ft_getopt(em, 'channels', [11, 12]); % F7, F8 by default
            em_amplitude = ft_getopt(em, 'amplitude', 10);
            em_duration = ft_getopt(em, 'duration', 0.2);
            em_frequency = ft_getopt(em, 'frequency', 3);

            nsamp_saccade = round(em_duration * cfg.fsample);
            for i = 1:round(em_frequency)
                start = randi([1, nsamples - nsamp_saccade + 1]);
                direction = sign(randn); % +1 (right) or -1 (left)
                
                % Rightward: F7 negative, F8 positive | Leftward: F7 positive, F8 negative
                for j = 1:length(em_channels)
                    chan = em_channels(j);
                    plateau = direction * (-1)^j * em_amplitude * ones(1, nsamp_saccade);
                    trialdata(chan, start:(start + nsamp_saccade - 1)) = ...
                        trialdata(chan, start:(start + nsamp_saccade - 1)) + plateau;
                end
            end
        end

        if cfg.artifacts.sweat.enable
            s = cfg.artifacts.sweat;
            s_channels = ft_getopt(s, 'channels', []);
            s_amplitude = ft_getopt(s, 'amplitude', 5);
            s_trials_field = ft_getopt(s, 'trials', 0.5);

            s_trials_selected = select_partial_trials(cfg, s_trials_field);
            if ismember(trl, s_trials_selected)
                for chan = s_channels
                    t = time - cfg.triallength/2;
                    trend = s_amplitude * (t / (cfg.triallength/2)).^2;
                    trialdata(chan, :) = trialdata(chan, :) + trend;
                end
            end
        end

        if cfg.artifacts.heart.enable
            h = cfg.artifacts.heart;
            h_channels = ft_getopt(h, 'channels', []);
            h_amplitude = ft_getopt(h, 'amplitude', 5);
            h_frequency = ft_getopt(h, 'frequency', 1);
            h_duration = ft_getopt(h, 'duration', 0.1);

            nsamp_pulse = round(h_duration * cfg.fsample);
            t = linspace(-3, 3, nsamp_pulse);
            pulse_shape = h_amplitude * tpdf(t, 2) / max(tpdf(t, 2));
            period = round(cfg.fsample / h_frequency);
            num_pulses = floor(nsamples / period);
            for i = 1:num_pulses
                start = (i-1) * period + 1;
                if start + nsamp_pulse - 1 <= nsamples
                    for chan = h_channels
                        trialdata(chan, start:(start + nsamp_pulse - 1)) = ...
                            trialdata(chan, start:(start + nsamp_pulse - 1)) + pulse_shape;
                    end
                end
            end
        end

        if cfg.artifacts.line_noise.enable
            ln = cfg.artifacts.line_noise;
            ln_channels = ft_getopt(ln, 'channels', []);
            ln_amplitude = ft_getopt(ln, 'amplitude', 2);
            ln_frequency = ft_getopt(ln, 'frequency', 60);

            for chan = ln_channels
                noise = ln_amplitude * sin(2 * pi * ln_frequency * time);
                trialdata(chan, :) = trialdata(chan, :) + noise;
            end
        end

        if cfg.artifacts.electrode_pop.enable
            ep = cfg.artifacts.electrode_pop;
            ep_channels = ft_getopt(ep, 'channels', []);
            ep_amplitude = ft_getopt(ep, 'amplitude', 50);
            ep_frequency = ft_getopt(ep, 'frequency', 1);
            ep_duration = ft_getopt(ep, 'duration', 0.2);

            nsamp_pop = round(ep_duration * cfg.fsample);
            for i = 1:round(ep_frequency)
                start = randi([1, nsamples - nsamp_pop + 1]);
                pop_shape = ep_amplitude * ones(1, nsamp_pop);
                for chan = ep_channels
                    trialdata(chan, start:(start + nsamp_pop - 1)) = ...
                        trialdata(chan, start:(start + nsamp_pop - 1)) + pop_shape;
                end
            end
        end

        data.trial{trl} = trialdata;
        data.sampleinfo(trl, :) = [begsample, begsample + nsamples - 1];
        begsample = begsample + nsamples;
    end
end

% Helper functions
function noise = bandlimited_noise(nsamples, fsample, freq_range, amplitude)
    t = (0:(nsamples-1)) / fsample;
    noise = zeros(1, nsamples);
    freqs = linspace(freq_range(1), freq_range(2), 50);
    for f = freqs
        phase = 2 * pi * rand;
        noise = noise + sin(2 * pi * f * t + phase);
    end
    noise = amplitude * noise / std(noise);
end

function trials = select_partial_trials(cfg, trials_field)
    if isscalar(trials_field)
        n_select = round(trials_field * cfg.ntrials);
        trials = randsample(cfg.ntrials, n_select);
    else
        trials = trials_field;
    end
end