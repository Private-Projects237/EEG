
% % % % Part 1: Generated Stationary Signal % % % % % % 

% Set pathway
EEGFUN_Path = '/Users/leandroledesma/Documents/Github/EEG';
addpath(EEGFUN_Path)

% Set parameters
chanNum = 10;
srate = 1000;
sigL = 120;
trialNum = 5;
sinNum = 15;
seed = 333;
noise = 3;
fig = "Yes"; 
chan2use = 1; 

% Use custom made function to create a signal - Part 2
nsStr = creatSig2(chanNum, srate, sigL, trialNum, sinNum, noise, fig, chan2use, seed)
signal = nsStr.Signal;

% Set fft parameters
fig = "Yes";
xmax = 37;

% Use another custom made function to obtain fft info
fft_info = fftx2(signal, srate, "Yes", xmax, chan2use)


% Set welch parameters
winsec = 2; 
nOverlap_per = 50;

% Use another custum made function to obtain Welch's method info
welch_info = welchx2(signal, srate, winsec, nOverlap_per, fig, xmax, chan2use)


% % % % Part 2: Generated Non-Stationary Signal % % % % % % 

% Set pathway
EEGFUN_Path = '/Users/leandroledesma/Documents/Github/EEG';
addpath(EEGFUN_Path)

chanNum = 10;
srate = 500;
sigL = 10;
transf_sec = .25;
trialNum = 2;
sinNum = 15;
noise = 3;
fig = "Yes";
chan2use = 1;
seed = 123;

% Create a non stationary signal 
nsStr2 = creatSig3(chanNum, srate, sigL, trialNum, transf_sec, sinNum , noise, fig, chan2use, seed)
signal = nsStr2.Signal;

% Set fft parameters
fig = "Yes";
xmax = 45;
chan2use = 1;

% Run fftx2
fft_info = fftx2(signal, srate, "Yes", xmax, chan2use)

% Set welch parameters
winsec = 2; 
nOverlap_per = 50;

% Run welchx2
welch_info = welchx2(signal, srate, winsec, nOverlap_per, fig, xmax, chan2use)


% % % % Part 3: EEG Data 1 % % % % % % 

% Set pathway
EEGFUN_Path = '/Users/leandroledesma/Documents/Github/EEG';
addpath(EEGFUN_Path)


% Let's put these functions to work
cd('/Users/leandroledesma/Documents/Udemy/Complete neural signal processing and analysis; Zero to hero/Section5/uANTS_static_MATLABfiles')
load restingstate64chans.mat
signal = EEG.data;
srate = EEG.srate;


% Set fft parameters
fig = "Yes";
xmax = 45;
chan2use = 1;

% Run fftx2
fft_info = fftx2(signal, srate, "Yes", xmax, chan2use)

% Set welch parameters
winsec = 2; 
nOverlap_per = 50;

% Run welchx2
welch_info = welchx2(signal, srate, winsec, nOverlap_per, fig, xmax, chan2use)


% % % % Part 4: EEG Data 2 % % % % % % 

% Set pathway
EEGFUN_Path = '/Users/leandroledesma/Documents/Github/EEG';
addpath(EEGFUN_Path)


% load data
load EEGrestingState.mat
N = length(eegdata);
signal = eegdata;


% Set fft parameters
fig = "Yes";
xmax = 45;
chan2use = 1;

% Run fftx2
fft_info = fftx2(signal, srate, "Yes", xmax, chan2use)

% Set welch parameters
winsec = 2; 
nOverlap_per = 50;

% Run welchx2
welch_info = welchx2(signal, srate, winsec, nOverlap_per, fig, xmax, chan2use)
