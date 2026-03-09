function [tab, data] = ft_erpmarkercount(cfg, data)
% FT_ERPMARKERCOUNT Takes in a FieldTrip dataset and reports the the
% frequency of each marker in the dataset using the .trialinfo field. As of
% right now, only works with a cell array structure that contains strings.
%
% INPUT
%   cfg.erpmarkercount.log = 'yes';
%

% Save the original configuration
cfg_org = cfg; 

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'erpmarkercount'});

% Set up configuration defaults
cfg.erpmarkercount = ft_getopt(cfg, 'erpmarkercount', struct());
log           = ft_getopt(cfg.erpmarkercount, 'log', 'yes');

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Get the count for all unique markers
tab = tabulate(data.trialinfo.eventvalue);

% Extract columns (column 1 = cellstr, column 2 = cell array of scalars)
names  = tab(:, 1);                      % Get the stimuli names
values = cell2mat(tab(:, 2));            % Get their occurance

% Use this function join the information from names and their frequency together
pieces = cellfun(@(name, val) sprintf('%s = %g;', name, val), ...
                 names, num2cell(values), ...
                 'UniformOutput', false);

% Convert the information into a vector 
oneRowString = strjoin(pieces, ' ');

% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'erpmarkercount';
    fun_name = 'ft_erpmarkercount';

    % Prepare the stats structure
    stats = [];
    stats.erpmarkercount = oneRowString;

    % Generate the log for this function
    data = ft_logstep(data, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_erpmarkercount log recorded\n');

end

end