% Set parameters
nbchan = 5;
trials = 10;
srate = 500;
trialsec = 10;
sinnum = 10;
noise = 3;
seed = 123;

% Use custom made function to create a signal - Part 2
newsig_info = creatSig2(nbchan, trials ,srate, trialsec, sinnum, noise, seed)

% Plot the created signal
plot_CreatSig2(newsig_info,1,30)

% run fftx2
fftx_info = fftx2(signal, srate)

% plot fftx2 results
plot_fftx2(fftx_info, 1, 30)

% run welchx2
welch_info = welchx2(signal, srate, 2, 50)

% plot welchx2
plot_welchx2(welch_info, 1, 30)
