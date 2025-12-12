function data = ft_eegvarsum(cfg, data)
% FT_EEGVARSUM Takes in a FieldTrip dataset and reports the global variance
% by concatenating the matrix into a vector and also variances for each
% channel.
%
% INPUT
%   cfg.eegvarsum.log = 'yes';
%

% Save the original configuration
cfg_org = cfg; 

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'eegvarsum'});

% Set up configuration defaults
cfg.eegvarsum = ft_getopt(cfg, 'eegvarsum', struct());
log           = ft_getopt(cfg.eegvarsum, 'log', 'yes');

% Extract all trials from the data and concatenate them
if ~isempty(data.trial)
X = cat(2, data.trial{:});

% Center each row (channel)
X_c = X - mean(X,2);

% Calculate the variance for each trial
chan_var = round(var(X_c, [], 2));

% Calculate a global variance
global_var =var (X_c(:));

else
global_var = NaN;
chan_var = NaN;

end

% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'eegvarsum';
    fun_name = 'ft_eegvarsum';

    % Prepare the stats structure
    stats = [];
    stats.chanvar = chan_var;
    stats.globalvar = round(global_var);

    % Generate the log for this function
    data = ft_logstep(data, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_eegvarsum log recorded\n');

end

end