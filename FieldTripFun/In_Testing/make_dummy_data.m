function data = make_dummy_data(nTrials, nChan, fs)
    data = struct();
    data.label   = arrayfun(@(x) sprintf('E%d',x), 1:nChan, 'UniformOutput', false)';
    data.fsample = fs;
    data.time    = repmat({(0:1/fs:2-1/fs)}, 1, nTrials);
    data.trial   = arrayfun(@(~) randn(nChan, fs*2), 1:nTrials, 'UniformOutput', false);
end