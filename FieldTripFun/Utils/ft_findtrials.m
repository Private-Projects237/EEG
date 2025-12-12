function trial_idx = ft_findtrials(cfg, data)
%FT_FINDTRIAL  Find trial numbers containing given time point(s) in seconds
%
% INPUT
%   cfg.time   - scalar or vector of time points in seconds (e.g. 60, [80 120])
%   data       - FieldTrip data structure with .sampleinfo and .fsample
%
%   OUTPUT
%     trial_idx   - vector of trial numbers (1-based), same length as cfg.time
%                   NaN if time not found in any trial
%
%   Example:
%     cfg.time = [60, 164, 300];
%
%   See also: ft_redefinetrial, ft_selectdata

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'time'});

% Validate data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Extract parameters
times_sec = cfg.time(:);
fs = data.fsample;
target_samples = round(times_sec * fs);

% Preallocate output
trial_idx = nan(size(times_sec));

% Vectorized search across all trials
start_samp = data.sampleinfo(:,1);
end_samp   = data.sampleinfo(:,2);

for i = 1:length(times_sec)
    samp = target_samples(i);
    
    % Find first trial where start <= samp <= end
    match = find(start_samp <= samp & samp <= end_samp, 1, 'first');
    
    if ~isempty(match)
        trial_idx(i) = match;
    end
end

% Return the trial numbers
trial_idx = trial_idx';

end