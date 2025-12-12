function data_out = dummy_robustdetrend2(data_in, cfg_user)
    data = data_in;
    pBad = cfg_user.robustdetrend2.proportion;
    nTrials = numel(data.trial);
    nBad = round(pBad * nTrials);
    rng('shuffle');
    badIdx = randperm(nTrials, nBad);
    keepIdx = setdiff(1:nTrials, badIdx);
    data.trial = data.trial(keepIdx);
    data.time  = data.time(keepIdx);

    stats.trials_in      = numel(data_in.trial);
    stats.trials_out     = numel(data.trial);
    stats.trials_removed = nBad;
    stats.bad_trial_idx  = badIdx;

    data = log_step(data, 'robustdetrend2', cfg_user, stats);
    data_out = data;
end