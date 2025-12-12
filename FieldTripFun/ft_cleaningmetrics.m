function S = ft_cleaningmetrics(cfg)
%FT_CLEANINGMETRICS  Evaluates artifact removal with localized metrics
%
% Usage:
%   S = ft_cleaningmetrics(cfg)
%
% Required cfg fields:
%   cfg.data_gt         = Ground truth (clean) data
%   cfg.data_noisy      = Data with simulated artifact
%   cfg.data_clean      = Data after ICA/artifact removal
%   cfg.affect_chan     = Cell array of channel labels with artifact (e.g. {'Fp1','Fp2'})
%                         Can also be a vector of numbers (e.g. [1:20])
%   cfg.unaffect_chan   = Cell array of channels *not* affected (e.g. {'Cz','Pz',...})
%
% Output:
%   S.global   = Global metrics (all channels)
%   S.local    = Localized: .contam (affected) and .clean (unaffected)
%   S.info     = Channel indices, labels, etc.
%   Printed table with all results

% Validating the cfg structure
cfg = ft_checkconfig(cfg, 'required', ...
    {'data_gt', 'data_noisy', 'data_clean', 'affect_chan', 'unaffect_chan'});

% Extracting the data
gt   = cfg.data_gt;
noisy = cfg.data_noisy;
est  = cfg.data_clean;
affect_chan = cfg.affect_chan;

% Saving information into shorter variable names
labels = gt.label;
fs = gt.fsample;

if ~ isnumeric(affect_chan) % If cell array do the following
    % Find channel indices
    idx_affect = find(ismember(labels, cfg.affect_chan));
    idx_unaffect = find(ismember(labels, cfg.unaffect_chan));
    
    % === MODIFIED PART START ===
    if isempty(cfg.affect_chan)
        % If affect_chan is empty, assume ALL channels except unaffect_chan are affected
        idx_unaffect = find(ismember(labels, cfg.unaffect_chan));
        idx_affect = setdiff(1:length(labels), idx_unaffect);
    else
        idx_affect = find(ismember(labels, cfg.affect_chan));
        idx_unaffect = find(ismember(labels, cfg.unaffect_chan));
    end
    
    % Only error if affect_chan was specified but none found
    if ~isempty(cfg.affect_chan) && isempty(idx_affect)
        error('No affected channels found. Check cfg.affect_chan labels.');
    end
    
    % Only warn if unaffect_chan was specified but none found
    if ~isempty(cfg.unaffect_chan) && isempty(idx_unaffect)
        warning('No unaffected channels found matching cfg.unaffect_chan. Using all non-affected as unaffected.');
        idx_unaffect = setdiff(1:length(labels), idx_affect);
    elseif isempty(idx_unaffect)
        % Original behavior: if unaffect_chan truly empty, use all non-affected
        idx_unaffect = setdiff(1:length(labels), idx_affect);
    end

else 
    idx_affect = affect_chan;
    idx_unaffect = setdiff(1:length(labels), affect_chan);
end


% === MODIFIED PART END ===

% Use to separate data into affected an unaffected channels
S.info.affect_labels = labels(idx_affect);
S.info.unaffect_labels = labels(idx_unaffect);
S.info.idx_affect = idx_affect;
S.info.idx_unaffect = idx_unaffect;

% Build valid raw-like structs
freq_gt = struct();
freq_gt.label       = labels;
freq_gt.fsample     = fs;
freq_gt.trial       = gt.trial;
freq_gt.time        = gt.time;
freq_gt.sampleinfo  = gt.sampleinfo;

freq_est = struct();
freq_est.label       = labels;
freq_est.fsample     = fs;
freq_est.trial       = est.trial;
freq_est.time        = est.time;
freq_est.sampleinfo  = est.sampleinfo;

% Run Welch's method
cfg_welch = [];
cfg_welch.method    = 'mtmfft';
cfg_welch.output    = 'pow';
cfg_welch.taper     = 'hanning';
cfg_welch.t_ftimwin = 2;
cfg_welch.toi       = 0:1:gt.time{1}(end);  % Forced to increase by 1 Hz for efficiency
cfg_welch.pad       = 'nextpow2';

freq_gt  = ft_freqanalysis(cfg_welch, freq_gt);
freq_est = ft_freqanalysis(cfg_welch, freq_est);

% Concatenate the trials 
flatten = @(x) cat(2, x{:});  % helper function

sig_gt    = flatten(gt.trial);
sig_noisy = flatten(noisy.trial);
sig_est   = flatten(est.trial);

% Compute metrics on subset
compute_metrics = @(sig_gt_sub, sig_est_sub, sig_noisy_sub) ...
    struct(...
    'mse',   mean((sig_gt_sub - sig_est_sub).^2, 'all'), ...
    'nrmse', sqrt(mean((sig_gt_sub - sig_est_sub).^2, 'all')) / rms(sig_gt_sub(:)), ...
    'rho',   corr(sig_gt_sub(:), sig_est_sub(:)), ...
    'SNR_before', 10*log10(var(sig_gt_sub(:)) / var(sig_noisy_sub(:) - sig_gt_sub(:))), ...  % ← FIXED
    'SNR_after',  10*log10(var(sig_gt_sub(:)) / var(sig_gt_sub(:) - sig_est_sub(:))) ...
    );

% global metrics (all channels) 
S.global = compute_metrics(sig_gt, sig_est, sig_noisy);
S.global.deltaSNR = S.global.SNR_after - S.global.SNR_before;

% Global spectral distance
Pgt = mean(freq_gt.powspctrm, [1 2]);
Pest = mean(freq_est.powspctrm, [1 2]);
S.global.SD = mean(abs(Pgt - Pest) ./ (Pgt + Pest + eps));

% Local metrics for contaminated channels
sig_gt_affect   = sig_gt(idx_affect, :);
sig_est_affect  = sig_est(idx_affect, :);
sig_noisy_affect = sig_noisy(idx_affect, :);

S.local.contam = compute_metrics(sig_gt_affect, sig_est_affect, sig_noisy_affect);
S.local.contam.deltaSNR = S.local.contam.SNR_after - S.local.contam.SNR_before;

% Spectral distance (contaminated only)
Pgt_c = mean(freq_gt.powspctrm(idx_affect, :), 1);
Pest_c = mean(freq_est.powspctrm(idx_affect, :), 1);
S.local.contam.SD = mean(abs(Pgt_c - Pest_c) ./ (Pgt_c + Pest_c + eps));

% Local metrics for unaffected channels
sig_gt_clean   = sig_gt(idx_unaffect, :);
sig_est_clean  = sig_est(idx_unaffect, :);
sig_noisy_clean = sig_noisy(idx_unaffect, :);

S.local.clean = compute_metrics(sig_gt_clean, sig_est_clean, sig_noisy_clean);
S.local.clean.deltaSNR = S.local.clean.SNR_after - S.local.clean.SNR_before;

Pgt_u = mean(freq_gt.powspctrm(idx_unaffect, :), 1);
Pest_u = mean(freq_est.powspctrm(idx_unaffect, :), 1);
S.local.clean.SD = mean(abs(Pgt_u - Pest_u) ./ (Pgt_u + Pest_u + eps));

% Calculating spectral distance both globally and locally
bands = struct('delta',[1 4], 'theta',[4 8], 'alpha',[8 12], 'beta',[13 30]);
band_names = fieldnames(bands);

for b = 1:length(band_names)
    f_idx = freq_gt.freq >= bands.(band_names{b})(1) & freq_gt.freq <= bands.(band_names{b})(2);
    
    % Global
    S.band_SD(b) = abs(mean(freq_gt.powspctrm(:,f_idx),'all') - mean(freq_est.powspctrm(:,f_idx),'all')) ...
        / (mean(freq_gt.powspctrm(:,f_idx),'all') + mean(freq_est.powspctrm(:,f_idx),'all') + eps);
    
    % Local: Contaminated
    S.local.contam.band_SD(b) = abs(mean(freq_gt.powspctrm(idx_affect,f_idx),'all') - mean(freq_est.powspctrm(idx_affect,f_idx),'all')) ...
        / (mean(freq_gt.powspctrm(idx_affect,f_idx),'all') + mean(freq_est.powspctrm(idx_affect,f_idx),'all') + eps);
    
    % Local: Unaffected
    S.local.clean.band_SD(b) = abs(mean(freq_gt.powspctrm(idx_unaffect,f_idx),'all') - mean(freq_est.powspctrm(idx_unaffect,f_idx),'all')) ...
        / (mean(freq_gt.powspctrm(idx_unaffect,f_idx),'all') + mean(freq_est.powspctrm(idx_unaffect,f_idx),'all') + eps);
end
S.band_labels = band_names;

%  Topographic Correlation (per channel) 
S.topo_rho = diag(corr(sig_gt', sig_est'));


% ==============================================================
% === SMART FORMATTER – DEFINED *BEFORE* PRINTING ============
% ==============================================================
fmt = @format_number_smart;

function str = format_number_smart(x)
    if isnan(x)
        str = 'NaN';
    elseif isinf(x)
        str = sprintf('%cInf', ternary(x > 0, '+', '-'));
    elseif abs(x) < 1e-3 && x ~= 0 || abs(x) > 1e3
        str = sprintf('%.2e', x);  % e.g., 2.44e-05
    else
        str = sprintf('%.2f', x);  % e.g., 0.99
    end
    str = sprintf('%12s', str);  % right-align in 12 chars
end

function out = ternary(cond, a, b)
    if cond, out = a; else, out = b; end
end


% ==============================================================
% === PRINT SUMMARY TABLE – NOW WORKS WITH 2 DECIMALS + SCI ===
% ==============================================================
fprintf('\n=== CLEANING EVALUATION ===\n');
fprintf('\nGlobal = all channels included');
fprintf('\nDenoised = noisy channels that were denoised');
fprintf('\nUnaffected = channels that did not have noise introduced into\n\n');

fprintf('\nNote: the metrics show the comparison of the three categories to the original signal (no noise)\n\n');

fprintf('%-20s %12s %12s %12s\n', '', 'Global', 'Denoised', 'Unaffected');
fprintf('%s\n', repmat('-',1,62));

% ---- Channels --------------------------------------------------
fprintf('%-20s %12s %12s %12s  →  %s\n', 'Channels', ...
        fmt(length(labels)), ...
        fmt(length(idx_affect)), ...
        fmt(length(idx_unaffect)), ...
        '');

% ---- Pearson ρ -------------------------------------------------
fprintf('%-20s %12s %12s %12s  →  %s\n', 'Pearson ρ', ...
        fmt(S.global.rho), ...
        fmt(S.local.contam.rho), ...
        fmt(S.local.clean.rho), ...
        '>0.98 excellent | 0.7–0.9 expected | >0.999 perfect');

% ---- MSE -------------------------------------------------------
fprintf('%-20s %12s %12s %12s  →  %s\n', 'MSE', ...
        fmt(S.global.mse), ...
        fmt(S.local.contam.mse), ...
        fmt(S.local.clean.mse), ...
        '<1e-3 excellent | <1e-2 good | >1 poor');

% ---- nRMSE -----------------------------------------------------
fprintf('%-20s %12s %12s %12s  →  %s\n', 'nRMSE', ...
        fmt(S.global.nrmse), ...
        fmt(S.local.contam.nrmse), ...
        fmt(S.local.clean.nrmse), ...
        '<0.10 good | 0.3–0.6 = cleaning | <0.01 perfect');

% ---- ΔSNR (dB) -------------------------------------------------
fprintf('%-20s %12s %12s %12s  →  %s\n', 'ΔSNR (dB)', ...
        fmt(S.global.deltaSNR), ...
        fmt(S.local.contam.deltaSNR), ...
        fmt(S.local.clean.deltaSNR), ...
        '>6 strong | >8 outstanding | ~0 expected');

% ---- Spectral Dist ---------------------------------------------
fprintf('%-20s %12s %12s %12s  →  %s\n', 'Spectral Dist (SD)', ...
        fmt(S.global.SD), ...
        fmt(S.local.contam.SD), ...
        fmt(S.local.clean.SD), ...
        '<0.05 negligible | 0.1–0.3 = artifact removed | <0.01 perfect');

% ---- Band Power SD ---------------------------------------------
bands = {'Delta', 'Theta', 'Alpha', 'Beta'};
fprintf('\n');
for b = 1:4
    fprintf('%-20s %12s %12s %12s\n', [bands{b} ' SD'], ...
            fmt(S.band_SD(b)), ...           % ← FIXED: was S.band_SD(1)
            fmt(S.local.contam.band_SD(b)), ...
            fmt(S.local.clean.band_SD(b)));
end
fprintf('\n');

% ---- Topo Correlation (min/mean/max) ---------------------------
fprintf('Topo Corr (min/mean/max):\n');
fprintf('  All:        %12s %12s %12s\n', ...
        fmt(min(S.topo_rho)), fmt(mean(S.topo_rho)), fmt(max(S.topo_rho)));
fprintf('  Denoised:   %12s %12s %12s\n', ...
        fmt(min(S.topo_rho(idx_affect))), ...
        fmt(mean(S.topo_rho(idx_affect))), ...
        fmt(max(S.topo_rho(idx_affect))));
fprintf('  Unaffected: %12s %12s %12s\n', ...
        fmt(min(S.topo_rho(idx_unaffect))), ...
        fmt(mean(S.topo_rho(idx_unaffect))), ...
        fmt(max(S.topo_rho(idx_unaffect))));
fprintf('\n');

end  % end of function