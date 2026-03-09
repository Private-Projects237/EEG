function report = ft_recommend_epochlength(cfg)
% FT_RECOMMEND_EPOCHLENGTH This function will recommend the best safe
% non-overlaping epoch length based on the difference between specified
% triggers in the ERP data. For this function to work, you must input a
% structure that contains 'event', 'trl', and other fields. These fields
% are all produced by using the ft_definetrial() on read in EEG marker
% data.
%
% INPUT (required):
% cfg.event = array of event structures (with .sample and .value fields)
% cfg.headerfile = path to header file (for sampling frequency)
%
% INPUT (optional):
% cfg.markers = cell-array of trigger values to consider (default = all triggers)
%               example: {'S 1', 'S 2', 'deviant'}
% cfg.units = 'time' (seconds, default) or 'samples'
% cfg.prestim = proposed pre-stimulus time in seconds (optional, for tailored poststim suggestion)
% cfg.soa_ms = stimulus onset asynchrony threshold in milliseconds (optional);
%              if specified, computes the proportion of inter-trigger intervals >= this value
% cfg.report_type = 'display', 'struct', or 'both' (default = 'both')
%
% OUTPUT:
% report = structure containing interval statistics and recommendations
%          (also prints report to screen if report_type includes 'display')
%
% See also: FT_DEFINETRIAL, FT_READEVENT, FT_READ_HEADER

% FieldTrip standard config handling
ft_checkconfig(cfg, 'required', {'event'});

% Default parameters
if ~isfield(cfg, 'markers'), cfg.markers = {}; end % empty = use all triggers
if ~isfield(cfg, 'units'), cfg.units = 'time'; end
if ~isfield(cfg, 'report_type'), cfg.report_type = 'both'; end
if ~isfield(cfg, 'soa_ms'), cfg.soa_ms = []; end

% Get sampling frequency (needed for time conversion)
if strcmp(cfg.units, 'time')
    if isfield(cfg, 'hdr')
        hdr = cfg.hdr;
    elseif isfield(cfg, 'headerfile')
        hdr = ft_read_header(cfg.headerfile);
    else
        ft_error('Cannot determine sampling frequency. Provide cfg.hdr or cfg.headerfile.');
    end
    Fs = hdr.Fs;
else
    Fs = 1; % dummy value when working in samples
end

% Select relevant events
events = cfg.event;

% Optional: filter by specific marker values
if ~isempty(cfg.markers)
    keep = false(size(events));
    for i = 1:numel(cfg.markers)
        keep = keep | strcmp({events.value}, cfg.markers{i});
    end
    events = events(keep);
end

if isempty(events)
    ft_error('No trigger events found (after optional filtering).');
end

% Sort events by sample number (just in case they're not ordered)
[~, sortidx] = sort([events.sample]);
events = events(sortidx);

% Calculate inter-trigger intervals
samples_diff = diff([events.sample]);
iti_samples = samples_diff;
iti_time = samples_diff / Fs; % always compute in seconds for potential SOA comparison

% Choose units for stats
if strcmp(cfg.units, 'time')
    iti = iti_time;
    unit_label = 'seconds';
else
    iti = iti_samples;
    unit_label = 'samples';
end

% Basic statistics
stats.min = min(iti);
stats.max = max(iti);
stats.mean = mean(iti);
stats.median = median(iti);
stats.n = numel(iti); % number of intervals = n_triggers - 1

% Recommendation
recommended_total_length = stats.min;
recommended_poststim = [];
if isfield(cfg, 'prestim') && ~isempty(cfg.prestim)
    recommended_poststim = stats.min - abs(cfg.prestim);
end

% Optional: Proportion above SOA
proportion_above_soa = [];
if ~isempty(cfg.soa_ms)
    soa_sec = cfg.soa_ms / 1000; % convert ms to seconds
    proportion_above_soa = mean(iti_time >= soa_sec); % proportion of ITIs >= SOA
end

% Prepare output structure
report = struct(...
    'n_triggers', numel(events), ...
    'n_intervals', stats.n, ...
    'min_iti', stats.min, ...
    'max_iti', stats.max, ...
    'mean_iti', stats.mean, ...
    'median_iti', stats.median, ...
    'units', unit_label, ...
    'recommended_total', recommended_total_length, ...
    'recommended_poststim', recommended_poststim, ...
    'prestim_used_for_suggestion', cfg.prestim, ...
    'soa_ms', cfg.soa_ms, ...
    'proportion_above_soa', proportion_above_soa);

% Display report if requested
if any(strcmpi(cfg.report_type, {'display', 'both'}))
    fprintf('\n=== Trigger Interval Analysis ===\n');
    fprintf('Triggers analyzed: %d\n', numel(events));
    fprintf('Intervals calculated: %d\n', stats.n);
    fprintf('ITI (%s):\n', unit_label);
    fprintf(' • min = %.3f\n', stats.min);
    fprintf(' • max = %.3f\n', stats.max);
    fprintf(' • mean = %.3f\n', stats.mean);
    fprintf(' • median = %.3f\n\n', stats.median);
    
    if ~isempty(proportion_above_soa)
        fprintf('Proportion of ITIs >= %d ms: %.3f (%.1f%%)\n\n', ...
            cfg.soa_ms, proportion_above_soa, proportion_above_soa * 100);
    end
    
    fprintf('Recommended maximum epoch length (pre + post): %.3f %s\n', ...
        recommended_total_length, unit_label);
    if ~isempty(recommended_poststim)
        fprintf(' → with prestim = %.3f s → max poststim ≈ %.3f s\n', ...
            cfg.prestim, recommended_poststim);
    end
    fprintf('→ Always use a bit less than the minimum to stay safe!\n\n');
    
    % Optional: show distribution
    figure('Name','Inter-Trigger Intervals','NumberTitle','off');
    histogram(iti, 25);
    xlabel(sprintf('Inter-Trigger Interval (%s)', unit_label));
    ylabel('Count');
    title('Distribution of time between consecutive triggers');
    grid on;
end
end