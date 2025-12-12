function ft_plotchantrialfft(cfg, data)
%FT_PLOTCHANTRIALFFT: Will produce heat maps (z-scored) representing delta, 
% theta, alpha, and beta frequency bands across channels and trials.
% Additionall, the mean power for each frequency band will be showcased as
% a bar graph.
%
% INPUT
%   cfg.plotchantrial.method       = 'mtmfft' (default);
%   cfg.plotchantrial.taper        = 'hanning' (default);
%   cfg.plotchantrial.output       = 'pow' (default);
%   cfg.plotchantrial.deltafoilim  = [1 4] (default);
%   cfg.plotchantrial.thetafoilim  = [4 8] (default);
%   cfg.plotchantrial.alphafoilim  = [8 12] (default);
%   cfg.plotchantrial.betafoilim   = [13 30] (default);
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'plotchantrial'});

% Set up configuration defaults
cfg.plotchantrial = ft_getopt(cfg, 'plotchantrial', struct());
method           = ft_getopt(cfg.plotchantrial, 'method', 'mtmfft');
taper            = ft_getopt(cfg.plotchantrial, 'taper', 'hanning');
output           = ft_getopt(cfg.plotchantrial, 'output', 'pow');
deltafoilim      = ft_getopt(cfg.plotchantrial, 'deltafoilim', [1 4]);
thetafoilim      = ft_getopt(cfg.plotchantrial, 'thetafoilim', [4 8]);
alphafoilim      = ft_getopt(cfg.plotchantrial, 'alphafoilim', [8 12]);
betafoilim       = ft_getopt(cfg.plotchantrial, 'betafoilim', [13 30]);

visibleplots = 'yes';
saveplots    = 'no';
main = 'no';

% Overrite configuration if saveplot field (structure) specified
if isfield(cfg, 'saveplots')
    visibleplots = cfg.saveplots.visibleplots;
    saveplots    = cfg.saveplots.saveplots;
    main         = cfg.saveplots.main;
    skip         = cfg.saveplots.skip;
    plotfolder   = cfg.saveplots.plotfolder;
end

% Specify whether the plot is visible or not
if strcmp(visibleplots, 'yes'); Show = 'on'; else; Show = 'off'; end

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Creata a frequency band matrix
FB = [deltafoilim; thetafoilim; alphafoilim; betafoilim];

% Create an empty object to hold z-scored power matrix and avg power
avg_pow = [];
z_pow =[];

% Run a for loop to get power avg value and matrix for each FB
for ii = 1:size(FB,1)
    % Compute power spectrum (method: mtmfft, taper: dpss)
    cfg = [];
    cfg.method     = method;
    cfg.taper      = taper;
    cfg.foilim     = FB(ii,:);      % sweat band
    cfg.output     = output;
    cfg.keeptrials = 'yes';       % keep each segment
    freq = ft_freqanalysis(cfg, data);
    
    % Average power within frequency bands (foilim)
    pow_per_trial_chan = squeeze(mean(freq.powspctrm, 3)); % trials x channel
    pow_per_chan_trial = pow_per_trial_chan'; % channel x trials
    avg_pow(ii) = mean(pow_per_chan_trial(:));
    
    % Convert the matrix into z-scores
    vector = pow_per_chan_trial(:);
    z_vector = zscore(vector);
    z_pow{ii} = reshape(z_vector, size(pow_per_chan_trial));
end

% Generate the plot
fig = figure('Visible', Show, 'Units','inches', ...
             'Position',[1 1 14 7], ...
             'PaperUnits','inches', ...
             'PaperPositionMode','manual', ...
             'PaperPosition',[0 0 14 7]);

% Create a 2x4 tiled layout (2 rows, 4 columns)
t = tiledlayout(2, 4, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Left segment: Top-left (Delta) ---
nexttile(t, 1); % Tile 1 (row 1, col 1)
imagesc(z_pow{1});
colorbar;
colormap(parula);
xlabel('Samples'); ylabel('Electrodes');
title('Delta (Z-scores) Across Channels and Trials');

% --- Left segment: Bottom-left (Theta) ---
nexttile(t, 5); % Tile 5 (row 2, col 1)
imagesc(z_pow{2});
colorbar;
colormap(parula);
xlabel('Samples'); ylabel('Electrodes');
title('Theta (Z-scores) Across Channels and Trials');

% --- Middle segment: Top-middle (Alpha) ---
nexttile(t, 2); % Tile 2 (row 1, col 2)
imagesc(z_pow{3});
colorbar;
colormap(parula);
xlabel('Samples'); ylabel('Electrodes');
title('Alpha (Z-scores) Across Channels and Trials');

% --- Middle segment: Bottom-middle (Beta) ---
nexttile(t, 6); % Tile 6 (row 2, col 2)
imagesc(z_pow{4});
colorbar;
colormap(parula);
xlabel('Samples'); ylabel('Electrodes');
title('Beta (Z-scores) Across Channels and Trials');

% --- Right segment: Full-height bar graph (merge col 3+4, both rows) ---
nexttile(t, 3, [2 2]); % Span 2 rows, 2 columns starting at tile 3
bar(1:4, avg_pow);
title('Avg Power For Delta, Theta, Alpha, Beta');
xlabel('Frequency Band'); 
ylabel('Average Power');
set(gca, 'XTickLabel', {'Delta', 'Theta', 'Alpha', 'Beta'});

% Optional: Improve overall figure title
title(t, 'Multi-Plot EEG Power Descriptives', 'FontSize', 14, 'FontWeight', 'bold');

 % If plots are to be saved then save them
if strcmp(saveplots, 'yes')
    cfg_sp = [];
    cfg_sp.fig = fig;
    cfg_sp.plotname = 'FBpowerspectra';
    cfg_sp.main = main;
    cfg_sp.skip = skip;
    cfg_sp.plotfolder = plotfolder;
    savehandlefig(cfg_sp)
end


end
