function [blinkIdx, data] = ft_findcompblinks(cfg, comp)
%FT_FINDCOMPBLINKS  Detects eye-blink components. It does so by counting
% the number of peaks within each component, which would resemble eye blink
% activity. If the thresholds are met and the component is mostly associated with 
% occular channels- based on information from the component matrix- then the
% signals will be marked for deletion.
%
%   blinkIdx = ft_findcompblinks(cfg, comp)
%
% INPUTS
%   cfg.compblinks.compnum   = 20 (default); number of components from
%       the comp.trial matrix it analyzes
%   cfg.compblinks.zthresh    = 3 (default); A threshold for identifying
%       blinks. Does not really have a unit but it works.
%   cfg.compblinks.min_dur    = 0.1 (default); Min seconds needed to be consider a blink  
%   cfg.compblinks.max_dur    = 0.5 (default); Max seconds needed to be considered a blink
%   cfg.compblinks.min_blinks = 10 (defaults); At least num of blinks
%       needed to be considered a blink component
%   cfg.compblinks.eyechannels = {'Fp1', 'Fp2', 'Fz'} (default); Use label names 
%   cfg.compblinks.thresh = .15 (default); Percentage of energy coming from blink channels
%   cfg.compblinks.blinkcompplot = 'no' (default);
%
% INPUTS (Time series data - MUST INCLUDE)
%   cfg.compblinks.data = data (FieldTrip framework)
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within
%
% OUTPUT
%     blinkIdx - vector of component indices (1-based) identified as blinks
%
%   See also KURTOSIS, PRCTILE, VAR

% Save the original configuration
cfg_org = cfg; 

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'compblinks'});

% Set up configuration defaults
cfg.compblinks = ft_getopt(cfg, 'compblinks', struct());
compnum    = ft_getopt(cfg.compblinks, 'compnum', 20);
zthresh    = ft_getopt(cfg.compblinks, 'zthresh', 3);
min_dur    = ft_getopt(cfg.compblinks, 'min_dur', 0.1);
max_dur    = ft_getopt(cfg.compblinks, 'max_dur', 0.5);
min_blinks = ft_getopt(cfg.compblinks, 'min_blinks', 10);
eyechannels = ft_getopt(cfg.compblinks, 'eyechannels', {'Fp1','Fp2', 'Fz'});
thresh      = ft_getopt(cfg.compblinks, 'thresh', .15);
blinkcompplot = ft_getopt(cfg.compblinks, 'blinkcompplot', 'no');

log        = ft_getopt(cfg.compblinks, 'log', 'no');

data       = ft_getopt(cfg.compblinks, 'data', [] );

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

% Validate the comp and data structures
comp = ft_checkconfig(comp, 'required', {'time', 'fsample', 'trial', 'topo', 'unmixing', 'label', 'topolabel'});
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});


% Extract the sampling rate
fs = comp.fsample;

% Extract top components (EEGLAB style)
X = cat(2, comp.trial{:});     % [nComp × total_samples]
X = X(1:compnum, :);            % keep only first compnum components

% Robust z-scoring
med = median(X, 2);
MAD = median(abs(X - med), 2);
MAD(MAD==0) = eps;
Z   = (X - med) ./ (1.4826 * MAD);   % [compnum × total_samples]

% Detect and count valid blink events per component
blink_count_per_comp = zeros(compnum, 1);

for c = 1:compnum
    suprathresh = abs(Z(c,:)) > zthresh;
    
    % Find start/stop of every contiguous suprathreshold segment
    edges  = diff([0 suprathresh 0]);
    starts = find(edges == 1);
    ends   = find(edges == -1) - 1;
    
    % Duration in samples
    durations = ends - starts + 1;
    
    % Keep only those within physiological blink duration
    valid = durations >= round(min_dur*fs) & durations <= round(max_dur*fs);
    
    blink_count_per_comp(c) = sum(valid);
end

% Save the blinks per components
blink_count_per_comp = blink_count_per_comp';

% Find components that meet peak requirements
meetPeaks = find(blink_count_per_comp > min_blinks);

% Keep only the components coming from occular channels
frontal_idx = find(ismember(comp.topolabel, eyechannels))';
pct_comp = abs(comp.topo) ./ sum(abs(comp.topo), 1);

% Proportion of absolute topography that falls into these frontal channels
frontal_share = sum(pct_comp(frontal_idx, :), 1);   % one value per component

% Default threshold: >50% of energy in Fp1/Fp2/Fz → almost certainly a blink
frontal_thresh = ft_getopt(cfg.compblinks, 'frontal_thresh', thresh);

% Final decision: must have enough blinks AND strong frontal projection
is_frontal_blink = (frontal_share >= frontal_thresh);

% Combine both criteria
blinkIdx = meetPeaks(is_frontal_blink(meetPeaks));
blinkIdx = blinkIdx(:)';

% Diagnostic Plot (How well the thresholds worked)
if strcmpi(blinkcompplot, 'yes')
    fig = figure('Visible', Show, 'Position', [100 100 1000 800]);
    
    % Generate three diagnostic plots
    subplot(3,1,1); bar(blink_count_per_comp); ylabel('Blink count');
    title('Number of detected blink-like events per component');
    subplot(3,1,2); bar(frontal_share*100); ylabel('% Frontal energy');
    title('Percentage of topography in Fp1/Fp2/Fz');
    subplot(3,1,3); bar(ismember(1:compnum, blinkIdx)*100);
    ylabel('Detected'); xlabel('Component');
    title(sprintf('Detected blink components: %s', mat2str(blinkIdx)));

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'blinkcompplotdiagnostic';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp);
        pause(.02);
    end
end

% Quick pause
pause(.01);

% If component plot was specified as yes = generate the plot
if strcmp(blinkcompplot, 'yes')
    % Shorten the matrix to the first minute
    total_samples = size(X,2);
    sec = 60;
    samples = sec * fs;
    min_samples = min(samples, total_samples);
    if min_samples > numel(X); min_samples = numel(X); end
    X = X(:,1:min_samples);
    
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
        if ismember(ch, blinkIdx)
            % Flat channels → blue
            plot(stacked_data(ch,:), 'Color', 'red', 'LineWidth', 1.8);
        else
            % Everything else → normal dark gray
            plot(stacked_data(ch,:), 'Color', good_color, 'LineWidth', 1);
        end
    end
    
    % Add the tiles and lables
    title('Detected Eye Components (1 Minute Recording)')
    xlabel('Sample Number'); 
    ylabel('Amplitude (stacked)');
    
    % Adds channel label information (very cool)
    yticks(channel_offset);
    yticklabels(comp.label);                            
    set(gca, 'FontSize', 8);
    
    axis ij; grid on; hold off;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'blinkcompplot';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp);
        pause(.02);
    end
end 

% Output message
if isempty(blinkIdx)
    fprintf('NO BLINK/HEART COMPONENTS DETECTED\n');
else
    fprintf('BLINK/HEART COMPONENT(S): %s\n', mat2str(blinkIdx));
end

% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'findblinkcomp';
    fun_name = 'ft_findcompblinks';

    % Prepare the stats structure
    stats = [];
    stats.blinkcomp = blinkIdx';
    stats.blinkcompnum = length(blinkIdx);
    stats.successful = 'yes';

    % Generate the log for this function
    data = ft_logstep(data, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_findcompblinks log recorded\n');

end

end 




