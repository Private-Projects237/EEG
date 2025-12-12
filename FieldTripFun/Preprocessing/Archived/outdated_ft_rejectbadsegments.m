function data = ft_rejectbadsegments(cfg, data)
% FT_REJECTBADSEGMENTS This function uses trial variance over median trial
% variance ratios to identidy noise channels.
% 
% INPUT
%   cfg.rejectbadseg.length     = 2 (default); segment seconds
%   cfg.rejectbadseg.thresh     = 5 (default); x times larger than median trial variace
%   cfg.rejectbadseg.badsegplot = 'no' (default); creates a plot of identified bad trials 
%
% OUPUT
%   cleaned_data

% Check configuration for correct parameters
cfg = ft_checkconfig(cfg, 'required', {'rejectbadseg'});

% Set up configuration defaults
cfg.rejectbadseg = ft_getopt(cfg, 'rejectbadseg', struct());
length  = ft_getopt(cfg.rejectbadseg, 'length', 2);
thresh  = ft_getopt(cfg.rejectbadseg, 'thresh', 5);
badsegplot    = ft_getopt(cfg.rejectbadseg, 'badsegplot', 'no');

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Segment the data
cfg = [];
cfg.length  = length;      % segment (trial) length in seconds
cfg.overlap = 0;      % 0% overlap
data_segmented = ft_redefinetrial(cfg, data);

% Convert data into 3 dimensions, with trials as the 3rd (like EEGLAB)
X = cat(3, data_segmented.trial{:}); 

% Center the amplitudes within each channel within each trial   
X_centered = X - mean(X, 2);

% Take each trial and turn it into a single vector
X_flat = reshape(X_centered, [], 100); 

% Get the variance for each vector (represents a single trial)
var_per_trial = var(X_flat, 0, 1); 

% Get the trial variance to median trial variance ratio
med_var = median(var_per_trial) + eps;
ratio_to_med = var_per_trial / med_var;

% Produce a heat map of the low frequency cells
if strcmp(badsegplot, 'yes')
    figure;                                     
    hold on;           

    % Create the stem plot
    stem(ratio_to_med, 'LineWidth', 1.5, 'Color', [0 0.45 0.74]);   

    % Outlier trials 
    idx_big = find(ratio_to_med > thresh);                  

    % scatter the big points (filled for visibility)
    scatter(idx_big, ratio_to_med(idx_big), 80, ...    
            'MarkerEdgeColor', 'r', ...        % red border
            'MarkerFaceColor', 'none', ...     % hollow centre
            'LineWidth', 1.5);
    
    xlabel('Sample index'); ylabel('Power');
    title('Amplitude variance for each trial / median trial variance');
    grid on;
    hold off;
end 

% Get the index of the trials that are problematic
bad_segments = find(ratio_to_med > thresh);

% Define trials to KEEP (exclude the bad ones)
cfg = [];
cfg.trials = setdiff(1:size(data_segmented.trial, 2), bad_segments);

% Select the good trials
data = ft_selectdata(cfg, data_segmented);


% print out how many trials were removed
fprintf('Original trials: %d, After removal: %d\n', ...
        numel(data_segmented.trial), numel(data.trial));
fprintf('Overall %.1f%% of trials were removed\n', ...
        round((1 - numel(data.trial) / numel(data_segmented.trial))*100, 1));

end

% % Create a structure to delete bad segments
% cfg = [];
% cfg.rejectbadseg.length     = 2 ; % Segment length in seconds
% cfg.rejectbadseg.thresh     = 2 ; % 5 x larger than median to be an artifact
% cfg.rejectbadseg.badsegplot = 'yes'; % Create a plot of deleted segments
% 
% % Remove bad trials
% data = sweat_cleaned;



