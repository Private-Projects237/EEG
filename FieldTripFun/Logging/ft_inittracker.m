function data = ft_inittracker(data)
%FT_INITTRACKER Takes a FieldTrip 'data' object and adds the `.cfg` field if
% not already present. Specifically, it adds `.cfg.preproc`, which will populate
% the structure with the fields: history, summary, start and inpomatrix.
%
% history: contains all useful information for each preprocessing step within cells
% summary: contains all useful information from all preprpocessing steps in one field
% start: timestamp of when a function was used
% intpmatrix: how much of the data has been interpolated
% labels: channel labels that correspond to intpmatrix rows
%
% You must use this function for `ft_logstep()` to work within
% the preprocessing functions!
%
% USAGE
%   data = ft_inittracker(data)

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Create a .cfg field if not present
if ~isfield(data, 'cfg') 
    data.cfg = struct();
end

% Create a .preproc field within .cfg if not present
if ~isfield(data.cfg, 'preproc')
    data.cfg.preproc = struct('history', {{}}, ...
                              'summary', struct(), ...
                              'start', datestr(now,'yyyy-mm-dd HH:MM:SS'), ...
                              'intpmatrix', [], ...
                              'labels', {{}});
end

        
end
