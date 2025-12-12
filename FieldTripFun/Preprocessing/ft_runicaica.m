function [comp, data, x_rank] = ft_runicaica(cfg, data)
% FT_performingica = Runs Runica ICA on FieldTrip framework data. Will return
% back the components that make up the data. It does this through the 
% `ft_componentanalysis()` function- the main function to run ICA in
% FieldTrip.
%
% Tip: use `rng()` in the same code line to fix the ICA results
%
% INPUT
%    cfg.performingica.method = 'runica' (default);
%    cfg.performingica.log    = 'no' (default);
%
% USAGE
%   [comp, data] = ft_performingica(cfg, data);

% Save the original configuration
cfg_org = cfg; 

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'performingica'});

% Set up configuration defaults
cfg.performingica = ft_getopt(cfg, 'performingica', struct());
method        = ft_getopt(cfg.performingica, 'method', 'runica');
log           = ft_getopt(cfg.performingica, 'log', 'no');

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Check the rank of the data
x = cat(2, data.trial{:});
x_rank = rank(x);

% Run ICA
cfg = [];
cfg.method = method;      
cfg.numcomponent = x_rank; 
cfg.demean = 'yes'; % Done by default regardless

% Save the ICA matrix
comp = ft_componentanalysis(cfg, data);

% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'performingica';
    fun_name = 'ft_runicaica';

    % Prepare the stats structure
    stats = [];
    stats.rank = x_rank;
    stats.successful = 'yes';

    % Generate the log for this function
    data = ft_logstep(data, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_runicaica log recorded\n');

end

end
