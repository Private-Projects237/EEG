% Prerequisits

% 1. Set pathway to general functions
EEGFUN_Path = '/Users/leandroledesma/Documents/Github/EEG/generalfun';
addpath(EEGFUN_Path)

% 2. Set pathway to EEG data location
% Set pathway to functions
EEGDAT_Path = '/Users/leandroledesma/Documents/Github/EEG/EEGData';
addpath(EEGDAT_Path)


% % % % Part 1: Generated Stationary Signal % % % % % % 


% Set parameters
chanNum = 10;
srate = 1000;
sigL = 30;
trialNum = 5;
sinNum = 25;
seed = 123;
noise = 3;
fig = "Yes"; 
chan2use = 1; 

% Use custom made function to create a signal - Part 2
Sig = creatSig2(chanNum, srate, sigL, trialNum, sinNum, noise, fig, chan2use, seed)
signal = Sig.Signal;

% Optional: table(Sig.Frequencies', Sig.Amplitudes', 'VariableNames',{'Hz','Amp'})

% Set fft parameters
fig = "Yes";
xmax = 45;

% Use another custom made function to obtain fft info
fft_info = fftx2(signal, srate, fig, xmax, chan2use)


% Set welch parameters
winsec = 2; 
nOverlap_per = 50;

% Use another custum made function to obtain Welch's method info
welch_info = welchx2(signal, srate, winsec, nOverlap_per, fig, xmax, chan2use)


% % % % Part 2: Generated Non-Stationary Signal % % % % % % 

chanNum = 10;
srate = 500;
sigL = 10;
transf_sec = .5;
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
load restingstate64chans.mat
signal = EEG.data;
srate = EEG.srate;

% plot the eeg data
% plot(EEG.times, EEG.data(1,:,1))

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
