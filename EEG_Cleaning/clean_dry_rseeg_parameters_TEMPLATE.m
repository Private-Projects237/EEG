% = THIS IS A TEMPLATE
% = COPY THIS OVER TO YOUR PROJECT'S GITHUB!

preprocParams = struct();

% === General Settings ===
preprocParams.saveEEG = true;
preprocParams.saveQC = true;
preprocParams.skipProcessed = true;

% === Filtering ===
preprocParams.filt.low = 1;
preprocParams.filt.high = 30;

% === Bad Channel Detection ===
preprocParams.badCh.corrThresh = 0.4;
preprocParams.badCh.winLen = 4;
preprocParams.badCh.varSD = 5;

% === Interpolation ===
preprocParams.interp = true;

% === ASR ===
preprocParams.ASR.cutoff = 6;
preprocParams.ASR.winLen = 0.5;
preprocParams.ASR.maxDim = [];
preprocParams.ASR.noiseThresh = 0.7;
preprocParams.ASR.hp = 0.15;
preprocParams.ASR.minCorr = [-3.5, 5.5];
preprocParams.ASR.minRetain = 0.5;

% === Re-referencing ===
preprocParams.reRef.on = true;
preprocParams.reRef.chan = [10, 20];

% === Downsampling ===
preprocParams.down.on = true;
preprocParams.down.rate = 500;

% === ICA ===
preprocParams.ICA.on = true;
preprocParams.ICA.ext = 1;
preprocParams.ICA.pca = true;
preprocParams.ICA.lrate = 5e-5;
preprocParams.ICA.steps = 2000;
preprocParams.ICA.stopTol = 1e-7;

% === IC Label ===
preprocParams.ICL.on = true;
preprocParams.ICL.thresh = struct('eye', 0.8, 'muscle', 0.8, 'heart', 0.8, 'line', 0.8, 'chan', 0.8);

% === Component Removal ===
preprocParams.rmComp = true;
preprocParams.rmHighConf = true;

% === Rank Checking ===
preprocParams.chkRank = true;
