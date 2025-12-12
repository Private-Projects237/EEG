function data_out = dummy_robustdetrend(data_in, cfg_user)
    data = data_in;
    stats.trials_in  = numel(data.trial);
    stats.trials_out = numel(data.trial);
    stats.channels   = numel(data.label);
    data = log_step(data, 'robustdetrend', cfg_user, stats);
    data_out = data;
end