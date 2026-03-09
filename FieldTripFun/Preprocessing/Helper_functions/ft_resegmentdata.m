function data_segmented = ft_resegmentdata(cfg)
% FT_RESEGMENTDATA Resegments continuous FieldTrip data to match an epoched reference structure.
%
%   data_segmented = ft_resegmentdata(cfg)
%
% INPUT (Data Structure)
%   cfg.datatype       = 'rseeg' or 'erp'; related to
%       whether .sampleinfo info is included or not.
%
% Input (cfg struct with fields):
%   cfg.epoched_ref   : FieldTrip data struct (epoched) used as reference for structure.
%                       Must have fields like trial, time, sampleinfo, trialinfo, etc.
%   cfg.continuous    : FieldTrip data struct (continuous, single trial) to be segmented.
%                       Assumes it was concatenated from cfg.epoched_ref.trials.
%   cfg.restore_time  : Logical (default: true). If true, uses original time vectors from ref.
%                       If false, generates new relative time per trial (e.g., from 0).
%   cfg.merge_cfg     : Logical (default: true). If true, merges cfg fields from both inputs.
%
% Output:
%   data_segmented    : Segmented FieldTrip data struct matching epoched_ref structure.
%
% Assumptions:
% - continuous.trial{1} has the same total samples as sum of epoched_ref trial lengths.
% - Channels (label, elec) in continuous may differ (e.g., after bad channel removal).
% - No changes to time dimension during processing.
%
% Example usage:
%   cfg = [];
%   cfg.epoched_ref = orig_data_epoched;
%   cfg.continuous = processed_concat_data;
%   segmented_data = ft_resegmentdata(cfg);



% Extract the data type
datatype    = ft_getopt(cfg, 'datatype', []);

% Check and set defaults
if ~isfield(cfg, 'epoched_ref') || ~isfield(cfg, 'continuous')
    error('ft_resegmentdata: cfg must include epoched_ref and continuous fields.');
end
orig = cfg.epoched_ref;
cont = cfg.continuous;

if ~isfield(cfg, 'restore_time'), cfg.restore_time = true; end
if ~isfield(cfg, 'merge_cfg'), cfg.merge_cfg = true; end

% Validate compatibility
if numel(cont.trial) ~= 1
    error('ft_resegmentdata: continuous must have exactly one trial (concatenated).');
end
lengths = cellfun(@(x) size(x, 2), orig.trial);
total_samples = sum(lengths);
if size(cont.trial{1}, 2) ~= total_samples
    error('ft_resegmentdata: continuous trial length must match sum of epoched_ref trial lengths.');
end

% Compute cumulative starts for splitting (1-based indices)
cumstarts = [1, cumsum(lengths(1:end-1)) + 1];

% Start building output from continuous (inherits updated labels, elec, etc.)
data_segmented = cont;
data_segmented.trial = cell(1, numel(orig.trial));  % Preallocate cell array

% Split the continuous trial into epoched trials
processed_trial = cont.trial{1};
for i = 1:numel(lengths)
    end_idx = cumstarts(i) + lengths(i) - 1;
    data_segmented.trial{i} = processed_trial(:, cumstarts(i):end_idx);
end

% Restore per-trial metadata from original
data_segmented.sampleinfo = orig.sampleinfo;
if strcmp(datatype, 'erp')
    data_segmented.trialinfo = orig.trialinfo;
end

% Handle time: restore original or generate new relative
if cfg.restore_time
    data_segmented.time = orig.time;
else
    data_segmented.time = cell(1, numel(orig.trial));
    for i = 1:numel(orig.trial)
        nsamps = lengths(i);
        data_segmented.time{i} = (0:nsamps-1) / orig.fsample;
    end
end

% Other fields (fsample should match)
data_segmented.fsample = orig.fsample;

% Merge cfgs if requested (simple struct merge, continuous overrides if conflict)
if cfg.merge_cfg
    if isfield(orig, 'cfg') && isfield(cont, 'cfg')
        data_segmented.cfg = ft_structmerge(orig.cfg, cont.cfg);
    elseif isfield(orig, 'cfg')
        data_segmented.cfg = orig.cfg;
    elseif isfield(cont, 'cfg')
        data_segmented.cfg = cont.cfg;
    end
else
    data_segmented.cfg = cont.cfg;  % Default to continuous cfg
end

% Helper subfunction for merging structs (handles nested if needed, but simple here)
function s = ft_structmerge(s1, s2)
    s = s1;
    fields = fieldnames(s2);
    for f = 1:numel(fields)
        s.(fields{f}) = s2.(fields{f});
    end
end

end