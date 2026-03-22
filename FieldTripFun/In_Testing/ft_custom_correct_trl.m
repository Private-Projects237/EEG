function [trl_table, summary] = ft_custom_correct_trl(cfg)
% FT_CUSTOM_CORRECT_TRL   Create trl for trials where stimulus is followed by a target response
%
% [trl_table, summary] = ft_custom_correct_trl(cfg)
%
% Required fields in cfg:
%   cfg.dataset             = string, full path to raw file (with markers)
%   cfg.stim_values         = cellstr, e.g. {'S 1','S 2','S 3','S 4','S 5','S 6'}
%   cfg.target_response     = string, e.g. 'R 2'  (the response that qualifies the trial)
%   cfg.prestim             = scalar, pre-stimulus time in seconds
%   cfg.poststim            = scalar, post-stimulus time in seconds
%   cfg.new_marker_name     = string, new name for kept stimuli, e.g. 'correct' or 'hit'
%   cfg.condition_name      = string, specify the condition of the markers
%       for loggingpurposes (e.g., 'correct_target', 'incorrect_target')
%
% Optional fields in cfg (with defaults):
%   cfg.stim_type           = 'Stimulus' (default)
%   cfg.response_type       = 'Response' (default)
%   cfg.deletedouble        = true (default) - deletes empty rows prevents variable class problems
%   cfg.max_resp_delay_s    = Inf (default) - max allowed stim-to-resp delay in seconds
%   cfg.return_trl_as_table = true (default) - if false, returns numeric matrix instead
%
% Outputs:
%   trl_table   = table with columns: begsample, endsample, offset, orig_value, eventvalue, stim_num
%                 (or numeric matrix [begsample endsample offset] if cfg.return_trl_as_table = false)
%   summary     = struct with .n_stim_found, .n_conditional, .proportion, .message (also printed)

% --- Input validation & defaults ---
if ~isfield(cfg, 'dataset'),             error('cfg.dataset is required'); end
if ~isfield(cfg, 'stim_values'),         error('cfg.stim_values (cellstr) is required'); end
if ~isfield(cfg, 'target_response'),     error('cfg.target_response (string) is required'); end
if ~isfield(cfg, 'prestim'),             error('cfg.prestim (seconds) is required'); end
if ~isfield(cfg, 'poststim'),            error('cfg.poststim (seconds) is required'); end
if ~isfield(cfg, 'new_marker_name'),     error('cfg.new_marker_name (string) is required'); end
if ~isfield(cfg, 'condition_name'),      error('cfg.condition_name (string) is required'); end

if ~isfield(cfg, 'stim_type'),           cfg.stim_type = 'Stimulus'; end
if ~isfield(cfg, 'response_type'),       cfg.response_type = 'Response'; end
if ~isfield(cfg, 'deletedouble'),        cfg.deletedouble = false; end
if ~isfield(cfg, 'max_resp_delay_s'),    cfg.max_resp_delay_s = Inf; end
if ~isfield(cfg, 'return_trl_as_table'), cfg.return_trl_as_table = true; end

% --- Read header and events ---
hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);
srate = hdr.Fs;

% Convert to table for easy filtering
events_table = struct2table(event);

% Deleted rows with empty marker information
if cfg.deletedouble && height(events_table) > 0
    rows_to_remove = cellfun(@isempty, events_table{:, 2});
    events_table = events_table(~rows_to_remove, :);
    fprintf('Delete rows where marker info was empty.\n');
end


% --- Find stimulus events ---
stim_mask = strcmp(events_table.type, cfg.stim_type) & ...
            ismember(events_table.value, cfg.stim_values);
stims = events_table(stim_mask, :);

% Parse stim_num (assumes format 'S X' or 'SX' with optional space)
stims.stim_num = zeros(height(stims),1);
for i = 1:height(stims)
    val = strtrim(stims.value{i});
    stims.stim_num(i) = str2double(strrep(val, 'S', ''));
end

n_stim_found = height(stims);
fprintf('Found %d stimulus markers matching cfg.stim_values.\n', n_stim_found);

% --- Build trl ---
trl_rows = {};          % Initialize as empty cell array (mixed types)
n_conditional = 0;
max_resp_samples = round(cfg.max_resp_delay_s * srate);

for i = 1:height(stims)
    stim_sample = stims.sample(i);
    stim_value  = stims.value{i};
    stim_num    = stims.stim_num(i);
    
    % Find responses after this stimulus
    resp_mask = strcmp(events_table.type, cfg.response_type) & ...
                (events_table.sample > stim_sample);
    next_resps = events_table(resp_mask, :);
    
    if isempty(next_resps)
        continue;
    end
    
    % Take the first one (closest in time)
    resp_value  = next_resps.value{1};
    resp_sample = next_resps.sample(1);
    
    % Check delay limit
    if (resp_sample - stim_sample) > max_resp_samples
        continue;
    end
    
    % Check if this is the target response
    if strcmp(resp_value, cfg.target_response)
        begsample = stim_sample - round(cfg.prestim * srate);
        endsample = stim_sample + round(cfg.poststim * srate);
        offset    = -round(cfg.prestim * srate);
        
        % Append as cell row (preserves numeric + string types)
        trl_rows(end+1, :) = {begsample, endsample, offset, ...
                              stim_value, cfg.new_marker_name, stim_num};
        
        n_conditional = n_conditional + 1;
    end
end

% --- If 'trl_rows' is empty stop the function print a message
if isempty(trl_rows)
    disp('There are no marker combinations of this type. Returning empty objects');
    trl_table = [];
    summary = [];
    return;
end

% --- Create output trl ---
if cfg.return_trl_as_table
    trl_table = cell2table(trl_rows, ...
        'VariableNames', {'begsample', 'endsample', 'offset', ...
                          'orig_value', 'eventvalue', 'stim_num'});
    
    % Ensure numeric columns are double (usually automatic, but safe)
    if ~isempty(trl_table)
        trl_table.begsample = double(trl_table.begsample);
        trl_table.endsample = double(trl_table.endsample);
        trl_table.offset    = double(trl_table.offset);
        trl_table.stim_num  = double(trl_table.stim_num);
    end
else
    % Classic numeric trl matrix (only beg/end/offset)
    if ~isempty(trl_rows)
        trl_table = cell2mat(trl_rows(:,1:3));
    else
        trl_table = [];
    end
end

% --- Summary & logging ---
proportion = 0;
if n_stim_found > 0
    proportion = n_conditional / n_stim_found * 100;
end

summary = struct(...
    'condition_name', cfg.condition_name, ...
    'n_stim_found', n_stim_found, ...
    'n_conditional',    n_conditional, ...
    'proportion',   proportion, ...
    'message',      sprintf('Of %d stimuli, %d were followed by %s (%.1f%%).', ...
                            n_stim_found, n_conditional, cfg.target_response, proportion));

fprintf('\n=== Trial summary ===\n');
fprintf('%s\n', summary.message);
fprintf('Ready to use: cfg.trl = trl_table; then ft_redefinetrial(...)\n\n');

end