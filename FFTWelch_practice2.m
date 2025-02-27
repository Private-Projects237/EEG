% Set parameters
nbchan = 10;
trials = 10;
srate = 100;
trialsec = 10;
sinnum = 25;
noise = 2;
seed = 212;

% Use custom made function to create a signal - Part 2
newsig_info = creatSig2(nbchan, trials ,srate, trialsec, sinnum, noise, seed)

% Plot the created signal
plot_CreatSig2(newsig_info,1,30)

% run fftx2
fftx_info = fftx2(newsig_info.data, srate, 'filename_001')

% plot fftx2 results
plot_fftx2(fftx_info, 1, 40)

% run welchx2
welch_info = welchx2(newsig_info.data, srate, 2, 50, 'filename_001')

% plot welchx2
plot_welchx2(welch_info, 1, 40)


% Initialize struct array
afftx = struct(); 

% Define parameters
numFiles = 50;  % Number of files to process
bandNames = {'delta', 'theta', 'beta', 'alpha'};  % Frequency bands

% Define frequency bands (no gamma)
frequencyBands = [1, 4; 4, 8; 8, 13; 13, 30];  % [start, end] Hz for each band

% Set up FBpow to work

FBpow()



afftx_info(2).powavg
meanPowAvg = mean(cat(3, afftx_info.powavg), 3) % looks promising


mean(fftx_info(1).powavg,1)

size(fftx_info(1).powavg)

afftx_info(1).hz'


