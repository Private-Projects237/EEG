function [pendingRawNames, processedRawNames] = ft_notyetprocessed(cfg)
%FT_NOTYETPROCESSED  Return raw filenames that are pending / already processed.
%
%   [pendingRawNames, processedRawNames] = ft_notyetprocessed(cfg)
%
% INPUT
%   cfg.inputdir1      = string, first folder with raw files (required)
%   cfg.inputdir2      = string, optional second folder with raw files
%   cfg.outputdir      = string, folder with processed files (required)
%
%   cfg.inputpattern1  = string, pattern for raw files in inputdir1 (default '*.eeg')
%   cfg.inputpattern2  = string, pattern for raw files in inputdir2 (default same as 1)
%   cfg.outputpattern  = string, pattern for processed files (default '*_preproc.mat')
%
%   cfg.fullname       = 'yes' | 'no' (default 'no') – return full paths?
%
% OUTPUT
%   pendingRawNames    = cell array of raw filenames (or full paths) that are NOT processed
%   processedRawNames  = cell array of raw filenames (or full paths) that ARE processed

%% --------------------------------------------------------------------
%% 1. Input validation & defaults
%% --------------------------------------------------------------------
if ~isfield(cfg,'inputdir1'),   error('cfg.inputdir1 is required'); end
if ~isfield(cfg,'outputdir'),  error('cfg.outputdir is required'); end

cfg.inputpattern1  = ft_getopt(cfg,'inputpattern1','*.eeg');
cfg.inputpattern2  = ft_getopt(cfg,'inputpattern2',cfg.inputpattern1);
cfg.outputpattern  = ft_getopt(cfg,'outputpattern','*_preproc.mat');
cfg.fullname       = ft_getopt(cfg,'fullname','no');   % 'yes' or 'no'

% make sure directories exist
assert(exist(cfg.inputdir1,'dir')==7, 'inputdir1 does not exist');
if isfield(cfg,'inputdir2') && ~isempty(cfg.inputdir2)
    assert(exist(cfg.inputdir2,'dir')==7, 'inputdir2 does not exist');
end
if ~exist(cfg.outputdir,'dir'), mkdir(cfg.outputdir); end

%% --------------------------------------------------------------------
%% 2. Collect raw files (full paths + filenames)
%% --------------------------------------------------------------------
rawPaths = string.empty();   % full paths
rawNames = string.empty();   % just filenames

% ---- inputdir1 ----
d = dir(fullfile(cfg.inputdir1, cfg.inputpattern1));
if ~isempty(d)
    names = string({d.name});
    rawPaths = [rawPaths; fullfile(cfg.inputdir1, names)];
    rawNames = [rawNames; names];
end

% ---- inputdir2 (optional) ----
if isfield(cfg,'inputdir2') && ~isempty(cfg.inputdir2)
    d = dir(fullfile(cfg.inputdir2, cfg.inputpattern2));
    if ~isempty(d)
        names = string({d.name});
        rawPaths = [rawPaths; fullfile(cfg.inputdir2, names)];
        rawNames = [rawNames; names];
    end
end

if isempty(rawNames)
    pendingRawNames   = {};
    processedRawNames = {};
    fprintf('ft_notyetprocessed: No raw files found.\n');
    return;
end

%% --------------------------------------------------------------------
%% 3. Build expected processed filename for every raw file
%% --------------------------------------------------------------------
% Example:  "myfile.eeg"  →  "myfile_preproc.mat"
% We simply replace the *input* extension with the *output* pattern.
% The output pattern may contain a leading '*', which we keep as a wildcard.
%   → replace the part that matches the input pattern (without the path).

% Strip the leading '*' from the patterns if present (dir() already expands it)
inPat  = regexprep(cfg.inputpattern1, '^\*', '');
outPat = regexprep(cfg.outputpattern, '^\*', '');

% Replace the raw extension with the processed pattern
% Works even if the raw file name contains the pattern multiple times (unlikely)
expectedNames = strrep(rawNames, inPat, outPat);   % <-- strrep as requested

% Full paths to the expected processed files
expectedFull = fullfile(cfg.outputdir, expectedNames);

%% --------------------------------------------------------------------
%% 4. Check which expected files actually exist
%% --------------------------------------------------------------------
exists = isfile(expectedFull);   % logical vector, same order as rawNames

%% --------------------------------------------------------------------
%% 5. Return cell arrays (full paths or just names)
%% --------------------------------------------------------------------
if strcmpi(cfg.fullname,'yes')
    processedRawNames = unique(cellstr(rawPaths(exists)));
    pendingRawNames   = unique(cellstr(rawPaths(~exists)));
else
    processedRawNames = unique(cellstr(rawNames(exists)));
    pendingRawNames   = unique(cellstr(rawNames(~exists)));
end

fprintf('ft_notyetprocessed: %d total, %d processed, %d pending.\n', ...
        numel(rawNames), numel(processedRawNames), numel(pendingRawNames));
end