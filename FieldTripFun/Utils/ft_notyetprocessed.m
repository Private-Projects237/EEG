function [pendingRawNames, processedRawNames] = ft_notyetprocessed(cfg)
%FT_NOTYETPROCESSED Return raw filenames that are pending / already processed.
%
% [pendingRawNames, processedRawNames] = ft_notyetprocessed(cfg)
%
% INPUT
% cfg.inputdir1 = string, first folder with raw files (required)
% cfg.inputdir2 = string, optional second folder with raw files
% cfg.outputdir = string, folder with processed files (required)
%
% cfg.inputpattern1 = string or cell array of strings, pattern(s) for raw files in inputdir1 (default '*.eeg')
% cfg.inputpattern2 = string or cell array of strings, pattern(s) for raw files in inputdir2 (default same as 1)
% cfg.outputpattern = string or cell array of strings, pattern(s) for processed files (default '*_preproc.mat')
%
% cfg.fullname = 'yes' | 'no' (default 'no') – return full paths?
%
% OUTPUT
% pendingRawNames = cell array of raw filenames (or full paths) that are NOT processed
% processedRawNames = cell array of raw filenames (or full paths) that ARE processed

%% --------------------------------------------------------------------
%% 1. Input validation & defaults
%% --------------------------------------------------------------------
if ~isfield(cfg,'inputdir1'), error('cfg.inputdir1 is required'); end
if ~isfield(cfg,'outputdir'), error('cfg.outputdir is required'); end
cfg.inputpattern1 = ft_getopt(cfg,'inputpattern1','*.eeg');
cfg.inputpattern2 = ft_getopt(cfg,'inputpattern2',cfg.inputpattern1);
cfg.outputpattern = ft_getopt(cfg,'outputpattern','*_preproc.mat');
cfg.fullname = ft_getopt(cfg,'fullname','no'); % 'yes' or 'no'
% make sure directories exist
assert(exist(cfg.inputdir1,'dir')==7, 'inputdir1 does not exist');
hasInputDir2 = isfield(cfg,'inputdir2') && ~isempty(cfg.inputdir2);
if hasInputDir2
    assert(exist(cfg.inputdir2,'dir')==7, 'inputdir2 does not exist');
end
if ~exist(cfg.outputdir,'dir'), mkdir(cfg.outputdir); end

%% --------------------------------------------------------------------
%% 2. Collect raw files (full paths + filenames) and associated inPats
%% --------------------------------------------------------------------
rawPaths = string.empty(); % full paths
rawNames = string.empty(); % just filenames
inPats = string.empty();   % input pattern part to replace, per file

% Prepare input dirs and their patterns
inputDirs = {cfg.inputdir1};
inputPatterns = {cfg.inputpattern1};
if hasInputDir2
    inputDirs{end+1} = cfg.inputdir2;
    inputPatterns{end+1} = cfg.inputpattern2;
end

for i_dir = 1:numel(inputDirs)
    dir_name = inputDirs{i_dir};
    patterns = inputPatterns{i_dir};
    if ischar(patterns), patterns = {patterns}; end
    for p = 1:numel(patterns)
        pat = patterns{p};
        inPat = regexprep(pat, '^\*', '');
        d = dir(fullfile(dir_name, pat));
        if isempty(d), continue; end
        names = string({d.name}');
        num_this = numel(names);
        rawPaths = [rawPaths; fullfile(dir_name, names)];
        rawNames = [rawNames; names];
        inPats = [inPats; repmat(string(inPat), num_this, 1)];
    end
end

if isempty(rawNames)
    pendingRawNames = {};
    processedRawNames = {};
    fprintf('ft_notyetprocessed: No raw files found.\n');
    return;
end

% Remove duplicates (based on full paths)
[rawPaths, ia, ~] = unique(rawPaths);
rawNames = rawNames(ia);
inPats = inPats(ia);

%% --------------------------------------------------------------------
%% 3. Prepare output patterns
%% --------------------------------------------------------------------
outPatterns = cfg.outputpattern;
if ischar(outPatterns), outPatterns = {outPatterns}; end
outPats = cellfun(@(x) regexprep(x, '^\*', ''), outPatterns, 'UniformOutput', false);

%% --------------------------------------------------------------------
%% 4. Check existence of processed files for each raw
%% --------------------------------------------------------------------
num_raw = numel(rawNames);
isProcessed = false(num_raw, 1);
for r = 1:num_raw
    cur_inPat = inPats(r);
    for op = 1:numel(outPats)
        cur_outPat = outPats{op};
        expectedName = strrep(rawNames(r), cur_inPat, cur_outPat);
        expectedFull = fullfile(cfg.outputdir, expectedName);
        if isfile(expectedFull)
            isProcessed(r) = true;
            break;
        end
    end
end

%% --------------------------------------------------------------------
%% 5. Return cell arrays (full paths or just names)
%% --------------------------------------------------------------------
if strcmpi(cfg.fullname, 'yes')
    processedRawNames = unique(cellstr(rawPaths(isProcessed)));
    pendingRawNames = unique(cellstr(rawPaths(~isProcessed)));
else
    processedRawNames = unique(cellstr(rawNames(isProcessed)));
    pendingRawNames = unique(cellstr(rawNames(~isProcessed)));
end
fprintf('ft_notyetprocessed: %d total, %d processed, %d pending.\n', ...
        num_raw, numel(processedRawNames), numel(pendingRawNames));
end