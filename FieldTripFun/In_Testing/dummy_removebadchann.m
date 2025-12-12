function [data_out, bad_chans] = dummy_removebadchann(data_in, cfg_user)
    data = data_in;
    rng('shuffle');
    nBad = randi([1 5]);
    badIdx = randperm(numel(data.label), nBad);
    keepIdx = setdiff(1:numel(data.label), badIdx);
    for tr = 1:numel(data.trial)
        data.trial{tr} = data.trial{tr}(keepIdx,:);
    end
    data.label = data.label(keepIdx);
    bad_chans.label = data_in.label(badIdx);

    stats.channels_in      = numel(data_in.label);
    stats.channels_out     = numel(data.label);
    stats.channels_removed = nBad;
    stats.bad_labels       = bad_chans.label;

    data = log_step(data, 'removebadchann', cfg_user, stats);
    data_out = data;
end