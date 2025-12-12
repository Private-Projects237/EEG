function denoised_partchann = ft_manchansegmentrepair(cfg, bad_segments, noisy_data)
%FT_MANCHANSEGMENTREPAIR  Repair bad channels in manually-segmented noisy
% trials. (Used to be called ft_chansegmentrepair)
%
% Usage:
%   data_fixed = ft_chansegmentrepair(cfg, noisy_segments, noisy_data)
%
% INPUT:
%   cfg.artpadding    = padding (s) added to each segment (default 0.1)
%   cfg.proportion    = proportion of samples > thresh to flag a channel (default 0.4)
%   cfg.thresh        = amplitude threshold in median-absolute-deviation units (default 3)
%   cfg.mad_thresh    = number of robust SDs below median variance for flat-line detection (default 3)
%   cfg.method        = interpolation method for ft_channelrepair
%                         ('weighted' | 'average' | 'spline' …) (default 'weighted')
%   cfg.neighbours    = neighbour structure from ft_prepare_neighbours **REQUIRED**
%
%   bad_segments      = A n x 2 matrix with latencies indicating the start and 
%                         stop samples that have noise 
%   noisy_data        = FieldTrip raw data structure full recording- the
%                         original recording that needs to be cleaned. MUST
%                         contain a `.elec` field with electrode positions.
%
% OUTPUT:
%   denoised_partchann        = cleaned FieldTrip data structure (same format as input) with
%                         interpolated channels and full cfg provenance.
%
%   See also FT_CHANNELREPAIR, FT_REDEFINETRIAL, FT_PREPARE_NEIGHBOURS

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'artpadding', 'proportion', 'thresh', ...
                                       'mad_thresh', 'method', 'neighbours'});

% Set defaults to configuration structure
cfg.artpadding    = ft_getopt(cfg, 'artpadding',    0.1);
cfg.proportion    = ft_getopt(cfg, 'proportion',    0.4);
cfg.thresh       = ft_getopt(cfg, 'thresh',       3);
cfg.mad_thresh = ft_getopt(cfg, 'mad_thresh', 3);
cfg.method        = ft_getopt(cfg, 'method',        'weighted');

if ~isfield(cfg, 'neighbours')
    ft_error('cfg.neighbours is required – run ft_prepare_neighbours first.');
end

%  Basic input validation
if size(bad_segments,2) ~= 2
    ft_error('Input ''bad_segments'' must be a matrix with two columns indicating start and stop samples');
end

if ~isfield(noisy_data, 'trial') || ~iscell(noisy_data.trial)
    ft_error('Input ''noisy_data'' must contain a .trial cell array.');
end
if ~isfield(noisy_data, 'fsample')
    ft_error('Input ''noisy_data'' must contain .fsample.');
end

% Simplify the variable names
artpadding = cfg.artpadding; 
proportion = cfg.proportion; 
thresh =  cfg.thresh; 
mad_thresh =  cfg.mad_thresh; 
method = cfg.method; 
neighbours = cfg.neighbours; 

% Part 1: Add padding to the bad EEG segmants
begart      = bad_segments(:,1)-round(artpadding.*noisy_data.fsample);
endart      = bad_segments(:,2)+round(artpadding.*noisy_data.fsample);
offset      = zeros(size(endart));

% do not go before the start of the recording or the end (to correct for padding)
begart(begart<1) = 1;
endart(endart>max(noisy_data.sampleinfo(:,2))) = max(noisy_data.sampleinfo(:,2));

% Create a struct of just bad EEG data segments 
cfg_redftril      = [];
cfg_redftril.trl  = [begart endart offset];
data_bad = ft_redefinetrial(cfg_redftril, noisy_data);

% Part 2: Interpolate bad channels in artifact segments
data_fixed  = {};

for k = 1:size(data_bad.trial, 2)
    % Step 1: Existing artifact detection (for high-amplitude artifacts)
    w            = ones(size(data_bad.trial{1,k}));
    md           = median(abs(data_bad.trial{1,k}(:)));
    w(find(abs(data_bad.trial{1,k}) > thresh*md)) = 0;
    iBad         = find(mean(1-w,2) > proportion);
    [val iBad_a] = max(max(abs(data_bad.trial{1,k}.*(1-w)),[],2));
    if isempty(iBad)
        iBad     = find(mean(1-w,2) == max(mean(1-w,2)));
        warning(['Trial %d: Decreasing threshold to: %f'], k, max(mean(1-w,2)));
    end

    % Step 2: NEW - Detect low-variance/flatlined channels using MAD
    chan_var = var(data_bad.trial{1,k}, 0, 2); % Variance across time for each channel
    iBad_lowamp = [];

    % Compute MAD of channel variances
    median_var = median(chan_var);
    mad_var = median(abs(chan_var - median_var));
    robust_std = 1.4826 * mad_var; % Robust standard deviation estimate

    % Flag channels with variance significantly below the median
    low_var_threshold = median_var - mad_thresh * robust_std;
    iBad_lowamp = find(chan_var < low_var_threshold);

    % Debugging output: List flagged low-variance channels
    if ~isempty(iBad_lowamp)
        fprintf('Trial %d: Flagged low-variance channels (MAD-based, threshold = %.2e):\n', k, low_var_threshold);
        for ch = iBad_lowamp'
            fprintf('Channel %s: Variance = %.2e (median = %.2e, MAD = %.2e, robust SD = %.2e)\n', ...
                data_bad.label{ch}, chan_var(ch), median_var, mad_var, robust_std);
        end
    else
        fprintf('Trial %d: No low-variance channels detected (threshold = %.2e)\n', k, low_var_threshold);
    end

    % Step 3: Combine bad channels from artifact and low-variance detection
    iBad_combined = unique([iBad; iBad_a; iBad_lowamp]);
    fprintf('Trial %d: All bad channels: %s\n', k, strjoin(data_bad.label(iBad_combined), ', '));

    % Step 4: Interpolate bad channels
    cfg = [];
    cfg.badchannel = data_bad.label(iBad_combined);
    cfg.method     = method;
    cfg.neighbours = neighbours;
    cfg.trials     = k;
    if ~isempty(cfg.badchannel)
        data_fixed{1,k} = ft_channelrepair(cfg, data_bad);
    else
        data_fixed{1,k} = data_bad; % No bad channels, keep original trial
    end
end

% Combine the trials into one fixed data stucture
data_fixed = ft_appenddata([], data_fixed{:});

% Part 3: Delete original artifact segments from the EEG data
% Create a configuration for deleting bad EEG segments from original data
cfg                               = [];
cfg.artfctdef.minaccepttim        = 0.010;
cfg.artfctdef.reject              = 'partial';
cfg.artfctdef.badchannel.artifact = [begart endart];
data_kept = ft_rejectartifact(cfg, noisy_data);

% Create a new struct with good EEG segments + denoised EEG segments
denoised_partchann_mess = ft_appenddata([], data_kept, data_fixed);

% Part 4: Reconstruct exactly 100 trials to match original structure
cfg = [];
cfg.trl = [noisy_data.sampleinfo zeros(size(noisy_data.sampleinfo, 1), 1)];  % Original 100 trials with zero offset
denoised_partchann = ft_redefinetrial(cfg, denoised_partchann_mess);

end
