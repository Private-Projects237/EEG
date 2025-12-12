function data_atten = ft_attenuatepeaks(cfg, data)
%FT_ATTENUATEPEAKS This function was designed to attenuate the amplitudes of 
% specified channels. It's purpose is mainly to function as a precursor for 
% channel removal/interpolation using variance comparisons. By attenuating the
% peaks, we are less likely to remove channels or trials that have peak
% artifacts within them. The input and output is a FieldTrip data object.
% We do this by identifying blinks using robust z-scores (MAD), duration
% limits and padding, and then using linear interpolation on the peaks.
% Linear interpolation is (delta y)/ over (delta x) from start and end of the 
% blink sample, creating a slope that is multipled to the sample length of
% the blink starting at sample 1 plus adding the activity of the sample
% right before the blink starts (basic algebra).
%
% INPUT
%   cfg.attenuatepeaks.channel      = channels for detection & correction (default {'Fp1','Fp2'})
%   cfg.attenuatepeaks.zthresh      = robust z-score threshold (default 3)
%   cfg.attenuatepeaks.maxdur       = max blink duration in seconds (default 0.5)
%   cfg.attenuatepeaks.padding      = samples to pad around each blink (default 75)
%   cfg.attenuatepeaks.interpbuffer = extra samples beyond padded window used as clean anchors (default 30)
%   cfg.attenuatepeaks.attenblnkplot = 'yes'/'no'  plot before & after
%   cfg.attenuatepeaks.plotzoom     = vertical spacing factor for stacked plot
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (defaul);
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% OUTPUT
%   data_atten (a matrix of attenuated blinks)
    
% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'attenuatepeaks'});

% Set up configuration defaults
cfg.attenuatepeaks = ft_getopt(cfg, 'attenuatepeaks', struct());
channel       = ft_getopt(cfg.attenuatepeaks, 'channel', {'Fp1', 'Fp2'});
zthresh       = ft_getopt(cfg.attenuatepeaks, 'zthresh', 3);
maxdur        = ft_getopt(cfg.attenuatepeaks, 'maxdur', 0.5);
padding       = ft_getopt(cfg.attenuatepeaks, 'padding', 50);
interpbuffer  = ft_getopt(cfg.attenuatepeaks, 'interpbuffer', 30);  % extra clean margin
attenblnkplot = ft_getopt(cfg.attenuatepeaks, 'attenblnkplot','no');
plotzoom      = ft_getopt(cfg.attenuatepeaks, 'plotzoom', 6);

% Plot saving (same syntax as your original code)
visibleplots = 'yes'; saveplots = 'no'; skip = []; plotfolder = [];

% Overrite configuration if saveplot field (structure) specified
if isfield(cfg, 'saveplots')
    visibleplots = ft_getopt(cfg.saveplots, 'visibleplots', 'yes');
    saveplots    = ft_getopt(cfg.saveplots, 'saveplots',    'no');
    skip         = ft_getopt(cfg.saveplots, 'skip',         []);
    plotfolder   = ft_getopt(cfg.saveplots, 'plotfolder',   []);
end

% Specify whether the plot is visible or not
if strcmp(visibleplots, 'yes'); Show = 'on'; else; Show = 'off'; end

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Create some variables
fsample    = data.fsample;
maxSamples = round(maxdur * fsample);  % max blink length in samples

% Determine which channels to use for blink detection & attenuation
if ischar(channel) || iscell(channel)
    chanidx = match_str(data.label, channel);
else
    chanidx = channel(:)';
end

if isempty(chanidx)
    warning('ft_attenuatepeaks: No specified channels found returning original data');
    data_atten = data;
    return;
end

% Create a copy that will contain the fixed information
data_atten = data;

% Create a for loop to process each trial
for tr = 1:numel(data_atten.trial)
    X   = data_atten.trial{tr};                 % Nchan × Nsamples
    EOG = X(chanidx, :);                  % blink reference channels
    
    % Robust z-score (median / MAD)
    med = median(EOG, 2);
    mad = median(abs(EOG - med), 2);
    mad(mad==0) = eps;
    Z = abs( (EOG - med) ./ (1.4826 * mad) ) > zthresh;
    
    % Build blink mask per channel
    blinkmask = false(numel(chanidx), size(X,2));
    for c = 1:numel(chanidx)
        tmp = Z(c,:);
        
        % Remove unrealistically long events
        if maxSamples > 0
            d = diff([0 tmp 0]);
            starts = find(d==1);
            ends   = find(d==-1)-1;
            toolong = (ends-starts+1) > maxSamples;
            for k = find(toolong)
                tmp(starts(k):ends(k)) = false;
            end
        end
        
        % Apply padding
        if padding > 0
            d = diff([0 tmp 0]);
            starts = find(d==1);
            ends   = find(d==-1)-1;
            for k = 1:numel(starts)
                from = max(1, starts(k) - padding);
                to   = min(size(X,2), ends(k) + padding);
                tmp(from:to) = true;
            end
        end
        
        blinkmask(c,:) = tmp;
    end
    
    % Linear Interpolation
    for c = 1:numel(chanidx)
        idx = find(blinkmask(c,:));
        if isempty(idx), continue; end
        
        % Find contiguous segments
        segstart = idx([true, diff(idx)~=1]);
        segend   = idx([diff(idx)~=1, true]);
        
        for k = 1:numel(segstart)
            s = segstart(k);
            e = segend(k);
            
            % Define clean anchor points (extend beyond padded blink)
            left  = max(1,       s - interpbuffer);
            right = min(size(X,2), e + interpbuffer);
            
            % Linear interpolation
            xq = s:e;
            yq = interp1([left right], X(chanidx(c),[left right]), xq, 'linear');
            
            % Replace the blink segment
            X(chanidx(c), s:e) = yq;
        end
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