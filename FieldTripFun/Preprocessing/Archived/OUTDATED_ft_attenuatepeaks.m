function data_atten = ft_attenuatepeaks(cfg, data)
%FT_ATTENUATEPEAKS This function was designed to attenuate the amplitudes of 
% specified channels. It's purpose is mainly to function as a precursor for 
% channel removal/interpolation using variance comparisons. By attenuating the
% peaks, we are less likely to remove channels or trials that have peak
% artifacts within them. The input and output is a FieldTrip data object.
% We do this by identifying blinks using robust z-scores (MAD), duration
% limits and padding, and then multiplying that data by an attenuator.
%
% USAGE
%   data_atten = ft_attenuatepeaks(cfg, data)
%
% INPUT
% Configuration parameters (cfg):
%   cfg.attenuatepeaks.channel        = cell array with channel labels or vector of indices of the 
%       channels that contain the blink signal (default = {'Fp1','Fp2'})
%   cfg.attenuatepeaks.zthresh        = z-score threshold for detecting large amplitudes (default = 3)
%   cfg.attenuatepeaks.maxdur         = maximum duration of a blink in seconds (default = 0.5)
%   cfg.attenuatepeaks.padding        = number of samples to pad left and right of each blink (default = 75)
%   cfg.attenuatepeaks.attenuation    = factor by which blink periods are multiplied (e.g. 0.2 = 20% of original amplitude; default = 0.01)
%   cfg.attenuatepeaks.attenblnkplot  = Create before and after blink attenuated plots
%   cfg.attenuatepeaks.plotzoom       = How zoomed in we want the plots to be
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (defaul);
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% OUTPUT
%   data_atten (a matrix of attenuated blinks)
%

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'attenuatepeaks'});

% Set up configuration defaults
cfg.attenuatepeaks = ft_getopt(cfg, 'attenuatepeaks', struct());
channel       = ft_getopt(cfg.attenuatepeaks, 'channel', {'Fp1', 'Fp2'});
zthresh       = ft_getopt(cfg.attenuatepeaks, 'zthresh', 3);
maxdur        = ft_getopt(cfg.attenuatepeaks, 'maxdur', .5);
padding       = ft_getopt(cfg.attenuatepeaks, 'padding', {'Fp1', 'Fp2'});
attenuation   = ft_getopt(cfg.attenuatepeaks, 'attenuation', .2);
attenblnkplot = ft_getopt(cfg.attenuatepeaks, 'attenblnkplot', 'no');
plotzoom      = ft_getopt(cfg.attenuatepeaks, 'plotzoom', 6);

visibleplots = 'yes';
saveplots    = 'no';

% Overrite configuration if saveplot field (structure) specified
if isfield(cfg, 'saveplots')
    visibleplots = cfg.saveplots.visibleplots;
    saveplots    = cfg.saveplots.saveplots;
    skip         = cfg.saveplots.skip;
    plotfolder   = cfg.saveplots.plotfolder;
end

% Specify whether the plot is visible or not
if strcmp(visibleplots, 'yes'); Show = 'on'; else; Show = 'off'; end

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Create some variables
fsample = data.fsample;
maxSamples = round(maxdur * fsample);   % max allowed blink length in samples

% Determine which channels to use for blink detection & attenuation
if ischar(channel) || iscell(channel)
    chanidx = match_str(data.label, channel);
else % numeric indices
    chanidx = channel;
end
if isempty(chanidx)
    warning('None of the specified channels were found in the data- returning original data');
    data_atten = data;
    return;
end
nChan = numel(chanidx);

% Create a copy that will contain the fixed information
data_atten = data;

% Create a for loop to process each trial
for tr = 1:numel(data.trial)
    X = data.trial{tr};                     % Nchan x Nsamples
    
    % Extract the EOG/frontal channels for this trial
    EOG = X(chanidx, :);                    % nChan x Nsamples
    
    % Robust z-score (MAD) per channel 
    med = median(EOG, 2);
    MAD = median(abs(EOG - med), 2);
    
    % avoid division by zero
    MAD(MAD==0) = eps;
    Z = (EOG - med) ./ (1.4826 * MAD);      % robust z-score
    
    % Detect large amplitude samples
    large = abs(Z) > zthresh;           % logical, nChan x Nsamples
    
    % For each channel separately: remove unrealistically long events
    blinkmask = false(nChan, size(X,2));
    for c = 1:nChan
        tmp = large(c,:);
        
        % Remove events longer than maxdur
        if maxSamples > 0
            d = diff([0 tmp 0]);
            starts = find(d==1);
            ends   = find(d==-1)-1;
            long   = (ends - starts + 1) > maxSamples;
            for k = find(long)
                tmp(starts(k):ends(k)) = false;
            end
        end
        
        % Add padding 
        if padding > 0
            d = diff([0 tmp 0]);
            starts = find(d==1);
            ends   = find(d==-1)-1;
            for k = 1:numel(starts)
                from = max(1, starts(k) - padding);
                to   = min(length(tmp), ends(k) + padding);
                tmp(from:to) = true;
            end
        end
        
        blinkmask(c,:) = tmp;
    end
    
    % Attenuate the selected channels during blink periods
    for c = 1:nChan
        X(chanidx(c), blinkmask(c,:)) = X(chanidx(c), blinkmask(c,:)) * attenuation;
    end
    
    data_atten.trial{tr} = X;
end


% Generating plots if specified
if strcmp(attenblnkplot, 'yes')
    % Save the data as a matrix
    X = cat(2, data.trial{:});

    % Center the original data and spread out channels
    X_c = X - mean(X, 2);
    offset1 = plotzoom * std(X(:));
    channel_offset1 = (0:size(X,1)-1)' * offset1;
    stacked_data1 = X_c + channel_offset1;
    
    % Generate the plot
    fig = figure('Visible', Show, 'Position', [300 400 600 500]);
    plot(stacked_data1(:, 1:8000)', 'k', 'LineWidth', 1);
    title('Original Data');
    xlabel('Sample Number'); ylabel('Amplitude (stacked)');
    grid on;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'attenuatedpeaks';
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

    % Save the data as a matrix
    X_atten = cat(2, data_atten.trial{:});

    % Center the attenuated blinks data and spread out channels
    X_atten_c = X_atten - mean(X_atten, 2);
    offset2 = plotzoom * std(X_atten(:));
    channel_offset2 = (0:size(X_atten,1)-1)' * offset2;
    stacked_data2 = X_atten_c + channel_offset2;

    % Generate the plot
    fig = figure('Visible', Show, 'Position', [900 400 600 500]);
    plot(stacked_data2(:, 1:8000)', 'k', 'LineWidth', 1);
    title('Attenuated Blinks');
    xlabel('Sample Number'); ylabel('Amplitude (stacked)');
    set(gcf, 'Position', [900 400 600 500]);
    grid on;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'attenuatedpeaks';
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end
    
end



end

