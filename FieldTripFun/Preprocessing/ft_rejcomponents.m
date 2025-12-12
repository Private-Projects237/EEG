function data_rmvcmp = ft_rejcomponents(cfg, comp)
% FT_REJCOMPONENTS This is a custom made function that removes specified
% components from the FieldTrip framework EEG data. It does this by using
% the `ft_rejectcomponent()` FieldTrip function. This specific function was
% created to faciliate the logging process of the EEG data. 
%
% INPUT
%   cfg.rejcomp.blinkcomp = [] (default); a vector of components numbers to
%       be removed
%   cfg.rejcomp.preproc   = [] (default); preproc structure from `ft_findcompblinks()`
%   cfg.rejcomp.log       = 'no' (default);
%
% Save the original configuration
cfg_org = cfg; 

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'rejcomp'});

% Set up configuration defaults
cfg.rejcomp = ft_getopt(cfg, 'rejcomp', struct());
blinkcomp   = ft_getopt(cfg.rejcomp, 'blinkcomp', []);
preproc     = ft_getopt(cfg.rejcomp, 'preproc', []);
log         = ft_getopt(cfg.rejcomp, 'log', 'no');

% Validate input comp
comp = ft_checkconfig(comp, 'required', {'time', 'fsample', 'trial', 'topo', ...
                                         'unmixing', 'label', 'topolabel', 'sampleinfo'});

% Create a configuration with the components to remove
cfg = [];
cfg.component = blinkcomp; % Components to reject

% Reject the artifact blink components
data_rmvcmp = ft_rejectcomponent(cfg, comp);

% Update the data preproc structure from cfg
data_rmvcmp.cfg.preproc = preproc;

% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'rejectblinkcmp';
    fun_name = 'ft_rejecomponents';

    % Prepare the stats structure
    stats = [];
    stats.comprej = length(blinkcomp);
    stats.successful = 'yes';

    % Generate the log for this function
    data_rmvcmp = ft_logstep(data_rmvcmp, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_rejecomponents log recorded\n');

end

end