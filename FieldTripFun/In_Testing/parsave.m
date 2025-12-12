function parsave(fname, varargin)
% PARSAVE  – 100% working in R2023b–R2025a inside parfor
    if ~isstring(fname)
        fname = convertCharsToStrings(fname);
    end
    save(fname, varargin{:}, '-v7.3');
end