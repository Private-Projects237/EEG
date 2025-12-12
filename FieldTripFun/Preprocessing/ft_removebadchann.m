function [rmvchandata, bad_chans] = ft_removebadchann(cfg, data)
% FT_REMOVEBADCHANN This function uses channel variance over median channel
% variance ratios to identidy noisy channels. This includes, electrode
% pops and flatlined channels. Additionally, it removes 'noisy' electrodes
% that have high power in higher frequencies while accounting for muscle
% artifacts in the data (does not clean muscle artifacts) by using robust
% z-scores. Additionally, eye blinks can be detected and attenuated to
% reduce inflated variances in frontal electrodes.
%
% INPUT
%   data = EEG data in the FieldTrip format- preferrably continuous
%
% INPUT
%   cfg.removebadchann.concatenate    = 'yes' (default); 
%   cfg.removebadchann.mthresh1       = 5 (default):
%   cfg.removebadchann.mthresh2       = 0.05 (default);
%   cfg.removebadchann.zthresh        = 4 (default);
%   cfg.removebadchann.highfrqbp      = [30 140] (default);
%   cfg.removebadchann.rmvchanplot    = 'no' (default); (red = electrode pop, blue = flat channel, yellow = noisy)
%   cfg.removebadchann.log            = 'no' (default);
%   cfg.removebadchann.intpmatrixupdt = 'no' (default); creates/updates intpmatrix field
%
% INPUT (Special - Drops muscle artifact trials from channel variance calculation)
%   cfg.removebadchann.muscleprotection = 'no' (default); 
%
% INPUT (Special - Recommended for Eyes Open)
%   cfg.removebadchann.peakprotection = 'no' (default); Attenuates blink
%       amplitudes for specified channels when calculating electrode pop
%       variance.
%   cfg.removebadchann.blinkchans     = {}; cell array (ex: {'Fp1', 'Fp2'}
%   cfg.removebadchann.attenblnkplot  = 'no' (default);
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% OUTPUT
%   [data_rmv_chans, bad_chan_label]
%   

% Save the original configuration
cfg_org = cfg; 

% Check configuration for correct parameters
cfg = ft_checkconfig(cfg, 'required', {'removebadchann'});

% Set up configuration defaults
cfg.removebadchann = ft_getopt(cfg, 'removebadchann', struct());
concatenate        = ft_getopt(cfg.removebadchann, 'concatenate', 'yes');
mthresh1           = ft_getopt(cfg.removebadchann, 'mthresh1', 5);
mthresh2           = ft_getopt(cfg.removebadchann, 'mthresh2', 0.05);
zthresh            = ft_getopt(cfg.removebadchann, 'zthresh', 4);
highfrqbp          = ft_getopt(cfg.removebadchann, 'highfrqbp', [30 140]);
rmvchanplot        = ft_getopt(cfg.removebadchann, 'rmvchanplot', 'no');

muscleprotection   = ft_getopt(cfg.removebadchann, 'muscleprotection', 'no');

peakprotection     = ft_getopt(cfg.removebadchann, 'peakprotection', 'no');
blinkchans         = ft_getopt(cfg.removebadchann, 'blinkchans', []);
attenblnkplot      = ft_getopt(cfg.removebadchann, 'attenblnkplot', 'no');

log                = ft_getopt(cfg.removebadchann, 'log', 'no');
intpmatrixupdt     = ft_getopt(cfg.removebadchann, 'intpmatrixupdt', 'no');

visibleplots = 'yes';
saveplots    = 'no';
main = 'no';

% Overrite configuration if saveplot field (structure) specified
if isfield(cfg, 'saveplots')
    visibleplots = cfg.saveplots.visibleplots;
    saveplots    = cfg.saveplots.saveplots;
    main         = cfg.saveplots.main;
    skip         = cfg.saveplots.skip;
    plotfolder   = cfg.saveplots.plotfolder;
end

% Specify whether the plot is visible or not
if strcmp(visibleplots, 'yes'); Show = 'on'; else; Show = 'off'; end

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Error management
if strcmp(peakprotection, 'yes') && isempty(blinkchans)
    error('Error: Must specify .blinkchans for peakprotection')
end

% Create a temporary variable
dat = data;

% Concatenate the data if they are trials (and specified as 'yes')
if strcmp(concatenate, 'yes')
    cfg_con = [];
    cfg_con.continuous = 'yes'; 
    dat = ft_redefinetrial(cfg_con, data);
    fprintf('EEG data was concatenated succesfully\n');
end

% Additional variables to keep track of
temp_rmvtrials = 0;

% If muscle protection was specified as yes
if strcmp(muscleprotection, 'yes')

    % step 1: segment the EEG data into trials
    cfg_seg = [];
    cfg_seg.length  = 2;        % segment length in seconds
    cfg_seg.overlap = 0;        % 0 for non-overlapping (100% = fully overlapping)
    dat_seg = ft_redefinetrial(cfg_seg, dat);

    % step 2: band-pass filter high frequency information
    cfg_filt = [];
    cfg_filt.bpfilter   = 'yes';
    cfg_filt.bpfreq     = highfrqbp;
    cfg_filt.bpfiltord  = 4;          
    cfg_filt.padding    = 2;           
    cfg_filt.padtype    = 'mirror';   
    dat_filt = ft_preprocessing(cfg_filt, dat_seg);

    % step 3: calculate the variance for each trial
    EEG = cat(3, dat_filt.trial{:}); % chan x samples x trials
    trial_var = var(EEG, 0, [1 2]);
    trial_var = squeeze(trial_var)';

    % step 4: identify artifact trials using robust z-scores (exceeds z-thresh)
    median_val = median(trial_var);
    MAD_val    = median(abs(trial_var - median_val));
    if MAD_val == 0, MAD_val = eps; end
    z_pow = 0.6745 * (trial_var - median_val) / MAD_val;
    bad_trials = find(z_pow > zthresh);

    % step 5: delete bad trials from the data (update all other fields)
    dat_seg.trial(bad_trials)       = [];
    dat_seg.time(bad_trials)        = [];
    dat_seg.sampleinfo(bad_trials,:) = [];

    % step 6: save this information back into 'dat'
    cfg_cont = [];
    cfg_cont.continuous = 'yes';
    dat = ft_redefinetrial(cfg_cont, dat_seg);
    temp_rmvtrials = length(bad_trials);
   
end


% Best for eyes open conditions
if strcmp(peakprotection, 'yes')

    % Create a structure to run the ft_attenuatepeaks() function
    cfg_atten = [];
    cfg_atten.attenuatepeaks.channel       = blinkchans;
    cfg_atten.attenuatepeaks.zthresh       = 3;
    cfg_atten.attenuatepeaks.maxdur        = 0.5;
    cfg_atten.attenuatepeaks.padding       = 50; 
    cfg_atten.attenuatepeaks.interbuffer   = 20;
    cfg_atten.attenuatepeaks.attenblnkplot = attenblnkplot;
    cfg_atten.attenuatepeaks.plotzoom      = 6;

    % If saveplots is specified- add this into ft_attenuatepeaks
    if isfield(cfg, 'saveplots')
        cfg_atten.saveplots.visibleplots  = visibleplots;
        cfg_atten.saveplots.saveplots     = saveplots;
        cfg_atten.saveplots.main          = main;
        cfg_atten.saveplots.skip          = skip;
        cfg_atten.saveplots.plotfolder    = plotfolder;
    end

    % Return a matrix of attenuated channels
    dat = ft_attenuatepeaks(cfg_atten, dat);

end

%%%%%%%%%%%%%% CALCULATING CHANNEL VARIANCE STARTS HERE %%%%%%%%%%%%%%

% Calculate the variance of each channel
X = dat.trial{:};
chan_var = var(X, [], 2);

% Robust bad channel detector (ratio of variance over median variance)
med_var = median(chan_var) + eps;
ratio_to_med = chan_var / med_var;

% Identify electrode pops and flatlined channels
pop_chans = find(ratio_to_med > mthresh1)';     % > 5× median
flat_chans = find(ratio_to_med < mthresh2)';  % < 5% of median

% Part 1: Band-pass filter the data for higher frequencies
cfg_filt = [];
cfg_filt.bpfilter   = 'yes';
cfg_filt.bpfreq     = highfrqbp;
cfg_filt.bpfiltord  = 4;          
cfg_filt.padding    = 2;           
cfg_filt.padtype    = 'mirror';   
dat_filt = ft_preprocessing(cfg_filt, dat);

% Part 3: Identify high variance channels for high frq
X_filt = cat(2, dat_filt.trial{:});
chan_var = var(X_filt, [], 2);
median_val = median(chan_var);
MAD_val    = median(abs(chan_var - median_val));
if MAD_val == 0, MAD_val = eps; end
z_pow = 0.6745 * (chan_var - median_val) / MAD_val;
noise_chans = find(z_pow > zthresh)';

% Get the label names of the bad channels;
pop_chans_label = data.label([pop_chans]);
flat_chans_label = data.label([flat_chans]);
noise_chans_label = data.label([noise_chans]);

% Generate a plot of channels to be removed (by type)
if strcmp(rmvchanplot, 'yes')
    % Convert the FieldTrip data into a single matrix
    X = cat(2, data.trial{:});

    % Prepare the data
    X_c = X - mean(X, 2); % Remove mean per channel
    offset = 20 * median(abs(X(:) - median(X(:)))); % Spaces out channels
    channel_offset = (0:size(X,1)-1)' * offset;
    stacked_data = X_c + channel_offset;
    
    % Generate the plot
    fig = figure('Visible', Show, 'Position', [100 100 1000 800]);
    hold on;   % Important: we plot channel-by-channel
    
    % Default color for good channels (close to your original black)
    good_color = [0.3 0.3 0.3];   % dark gray
    
    for ch = 1:size(X,1)
        if ismember(ch, flat_chans)
            % Flat channels → blue
            plot(stacked_data(ch,:), 'Color', 'blue', 'LineWidth', 1.8);
        elseif ismember(ch, pop_chans)
            % Pop (jump) channels → red
            plot(stacked_data(ch,:), 'Color', 'red', 'LineWidth', 1.8);
        elseif ismember(ch, noise_chans)
            % Noisy channels → yellow (slightly softened so it's visible on white bg)
            plot(stacked_data(ch,:), 'Color', [1 0.85 0], 'LineWidth', 1.8);
        else
            % Everything else → normal dark gray
            plot(stacked_data(ch,:), 'Color', good_color, 'LineWidth', 1);
        end
    end
    
    % Add the tiles and lables
    title('Removed Channels: (Red = Elec Pop; Blue = Flat; Yellow = Noisy)')
    xlabel('Sample Number'); 
    ylabel('Amplitude (stacked)');

    % Adds channel label information (very cool)
    yticks(channel_offset);
    yticklabels(data.label);                            
    set(gca, 'FontSize', 8);
    
    axis ij
    grid on;
    hold off;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'rmvchannels';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

end

% Report types of bad channels found
if ~isempty(flat_chans)
    disp('Flat channels:'); disp(flat_chans_label);
else
    disp('Flat channels:'); disp('None'); 
end
if ~isempty(pop_chans)
    disp('Electrode Pops:'); disp(pop_chans_label);
else
    disp('Electrode Pops:'); disp('None'); 
end
if ~isempty(noise_chans)
    disp('High Frq channels:'); disp(noise_chans_label);
else
    disp('High Frq channels:'); disp('None'); 
end


% Combine all identified channels into one object
bad_chans_idx = unique([flat_chans, pop_chans, noise_chans]);

% Pick channels that are close to the median (1) that do not overlap with bad channels
[~, idx] = sort(abs(ratio_to_med - 1));
top6_idx = idx(1:6)';                      

% Extract the data and create three segments
X = data.trial{:};                                 
nSamples = size(X,2);
nPerPart = floor(nSamples/3);
segments = {1:nPerPart, nPerPart+1:2*nPerPart, 2*nPerPart+1:nSamples};

% If 'yes', plot each bad channel with 3 channels closest to median variance
if strcmp(rmvchanplot, 'yes')
    for ii = 1:length(bad_chans_idx)
        % Create a vector with one bad channel and 3 good ones
        bad_idx = bad_chans_idx(ii);
        chan_inx = [bad_idx, top6_idx];               
        
        % Pick noisiest third (segment) of the bad channel
        vars = cellfun(@(s) var(X(bad_idx,s)), segments);
        [~, worst] = max(vars);
        seg = segments{worst};
        
        % Index the data and time by the worst segment
        dat = X(chan_inx, seg);                        
        t   = (0:length(seg)-1) / data.fsample;
        
        % Generate the plot
        fig = figure('Visible', Show, 'Color','w','Position',[200 200 1000 500]);
        offset = 0;
        scale  = 20 * median(std(dat,[],2));           % automatic spacing
        
        hold on;
        for k = 1:4
            if k==1
                plot(t, dat(k,:) + offset, 'r', 'LineWidth', 2.2); % bad in red
            else
                plot(t, dat(k,:) + offset, 'Color', [0 .75 .75], 'LineWidth', 1.2);
            end
            offset = offset - scale;                   % move next trace down
        end
        hold off;
        
        % Adding axes and a title
        axis tight; box off;
        set(gca,'YTick',[],'YColor','none');
        xlabel('Time (s)');
        title(sprintf('Bad: %s  |  noisiest 1/3 of recording', data.label{bad_idx}), ...
              'Interpreter','none','FontSize',13,'FontWeight','bold');
        legend({'BAD', 'good', 'good', 'good'}, 'Location','eastoutside');

        % If plots are to be saved then save them
        if strcmp(saveplots, 'yes')
            cfg_sp = [];
            cfg_sp.fig = fig;
            cfg_sp.plotname = 'rmvindvchannel';
            cfg_sp.main = main;
            cfg_sp.skip = skip;
            cfg_sp.plotfolder = plotfolder;
            savehandlefig(cfg_sp)
        end
        
    end
end



% Return the bad channel labels and remove them from the data
if ~isempty(bad_chans_idx)
    bad_chans = data.label(bad_chans_idx);  
    cfg_rmvchan = [];
    cfg_rmvchan.channel = setdiff(data.label, bad_chans);  % keeps 29 good channels
    cfg_rmvchan.export = 'no';
    
    % Delete the noisy channels from the data
    rmvchandata = ft_preprocessing(cfg_rmvchan, data);
else
    % Return an empty object
    bad_chans = [];
    
    % Save the data as 'rmvchandata'
    rmvchandata = data;
end


% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'rmvbadchan';
    fun_name  = 'ft_removebadchann';

    % Prepare the stats structure
    stats = [];
    stats.peakprotetion = peakprotection;
    stats.muscleprotection = muscleprotection;
    stats.temptrialsrmv = temp_rmvtrials;
    stats.flat_chan = flat_chans_label;
    stats.pop_chan = pop_chans_label;
    stats.noise_chan = noise_chans_label;
    stats.rmvchannum = length(bad_chans_idx);
    stats.successful = 'yes';

    % Generate the log for this function
    rmvchandata = ft_logstep(rmvchandata, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('fr_removebadchann log recorded\n');

end


% Update .intpmatrix if specified yes
if strcmp(intpmatrixupdt, 'yes')
    
    % Check to see if .intpmatrix already exists
    intpmatrix = data.cfg.preproc.intpmatrix;
    if isempty(intpmatrix)
        % segment the EEG data into trials
        cfg_seg = [];
        cfg_seg.length  = 2;        % segment length in seconds
        cfg_seg.overlap = 0;        % 0 for non-overlapping (100% = fully overlapping)
        dat_seg = ft_redefinetrial(cfg_seg, data);
        intpmatrix = zeros(numel(dat_seg.label), numel(dat_seg.trial));
        rmvchandata.cfg.preproc.labels = dat_seg.label;
    end

    % Update the channels (rows) that had to be interpolated
    intpmatrix(bad_chans_idx,:) = 1;

    % Save this into the returned data
    rmvchandata.cfg.preproc.intpmatrix = intpmatrix;

    % Update that the log was recorded
    fprintf('fr_removebadchann intpmatrix was updated\n');

end

end
