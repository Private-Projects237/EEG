function data_out = dummy_ica(data_in, ~)
    % This will FAIL for sub03
    if isfield(data_in, 'fail_ica') && data_in.fail_ica
        error('ICA failed: not enough variance');
    end
    nComp = randi([2 6]);
    stats.components_in  = 64;
    stats.components_out = 64 - nComp;
    stats.components_removed = nComp;
    data_in = log_step(data_in, 'ica', struct(), stats);
    data_out = data_in;
end