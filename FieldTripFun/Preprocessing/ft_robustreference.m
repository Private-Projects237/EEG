function [data_referenced, mn]= ft_robustreference(cfg, data)
%FT_ROBUSTREFERNECE Uses robust rereferencing on the EEG data with the
% nt_rereference() function from the NoiseTools package. The robust part
% means that rereferencing occurs without including noise in channels into
% the average. This is done by weighting data samples that are noise to 0.
%
% Usage:
%   data_referenced = ft_robustreference(cfg, data)
%
% INPUT:
%   cfg.robustreference.thresh      = 3 (default); SD threshold to turn the
%       weight from a data sample into 0. 
%   cfg.robustreference.heatmap     = 'no' (default); Produces Z score heat map
%       within channel to show possible samples that are noisy and weighted as 0
%   cfg.robustreference.padding     = 100 (default); turns 100 samples left and
%       right of the identified 0 into 0's- to prevent ringing noise 
%   cfg.robustreference.channelplot = 'no' (default); Generates plot of EEG data after rereferencing
%   cfg.robustreference.log         = 'no' (default)
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% OUPUT:
%   data_referenced = robust referenced data
%   mn = a vector containing the subtracted referece

% Save the original configuration
cfg_org = cfg; 

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'robustreference'});

% Set up configuration defaults
cfg.robustreference = ft_getopt(cfg, 'robustreference', struct());
thresh      = ft_getopt(cfg.robustreference, 'thresh', 3);
heatmap     = ft_getopt(cfg.robustreference, 'heatmap', 'no');
padding     = ft_getopt(cfg.robustreference, 'padding', 100);
channelplot = ft_getopt(cfg.robustreference, 'channelplot', 'no');
log         = ft_getopt(cfg.robustreference, 'log', 'no');

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

% Concatenate all trials into one object
X = cat(2, data.trial{:});

% Get the z-scores for each value compared to all values in the matrix
vector = X(:);
z_vector = zscore(vector);
z_amp = reshape(z_vector, size(X));

% Create the weights 
w = abs(z_amp) < thresh; % Less than thresh get the value 1 (above is 0)

% Create a kernal for the padding
kernel = ones(1, 2*padding + 1);  

% Add some zero padding into the ones matrix 
w_padded = w;
for ch = 1:size(w,1)
    bad = ~w(ch,:);                                   % 1 = bad
    expanded_bad = conv(bad, kernel, 'same') > 0;     % dilate ±20
    w_padded(ch,:) = ~expanded_bad;                   % 1 = good
end

% Print a heat map of the amplitude z-scores 
if strcmp(heatmap, 'yes')
    fig = figure('Visible', Show, 'Position', [100 100 1000 800]);
    ft_quickplot2(w_padded); colormap(hot);
    title('Dashes = Weighted Zero Samples (+ Padding)')

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'robustreferenceweight0';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end
end

% transponse the data and weight matrix
x_t = X'; w_t = w_padded';

% Get the robust reference
[y, mn] = nt_rereference(x_t, w_t);

% Change it back into channels x sample
x_reference = y';

% Convert this information back into trials
trial_samples = size(data.trial{1},2);
nTrials = size(x_reference,2) / trial_samples;

% Set variables to hold loop information
trials = {};
start_samp = 1;
end_samp = trial_samples;

% Create a for loop that segments the data by save size as inputed data
for ii = 1:nTrials
    trials{ii} = x_reference(:,start_samp:end_samp);
    start_samp = start_samp + trial_samples;
    end_samp = end_samp + trial_samples; 
end

% Create a copy of the data
data_referenced = data;

% Replace the original trials with the referenced ones
data_referenced.trial = trials;

% If a plot was specified 
if strcmp(channelplot, 'yes')

    % Convert the FieldTrip data into a single matrix
    X = cat(2, data_referenced.trial{:});
    
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
        % Everything else → normal dark gray
        plot(stacked_data(ch,:), 'Color', good_color, 'LineWidth', 1);
    end

    % Add the tiles and lables
    title('After Robust Detrending')
    xlabel('Sample Number'); 
    ylabel('Amplitude (stacked)');
    
    % Adds channel label information (very cool)
    yticks(channel_offset);
    yticklabels(data_referenced.label);                            
    set(gca, 'FontSize', 8);
    
    axis ij; grid on; hold off;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'robustreferenceddata';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end
   
end

% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'robustrereference';
    fun_name = 'ft_robustreference';

    % Prepare the stats structure
    stats = [];
    stats.successful = 'yes';

    % Generate the log for this function
    data_referenced = ft_logstep(data_referenced, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_robustreference log recorded\n');

end

end

