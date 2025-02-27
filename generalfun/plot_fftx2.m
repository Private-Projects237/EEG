% INPUT
% fftx_info: output from `fftx2()`
% chan2use: choose channel to plot
% xmax: x-axis max cut-off
%
% OUPUT (Plots):
% Plot 1: Avg Amplitudes for frequencies in one channel
% Plot 2: Avg Power for frequencies in one channel
%
% Example:
% plot_fftx2(fftx_info, 1, 30)

function plot_fftx2(fftx_info, chan2use, xmax)

    % Extract the hz, amplitude avg, and power spectral density
    hz = fftx_info.hz;
    ampavg = fftx_info.ampavg;
    powavg = fftx_info.powavg;
    trials = fftx_info.trials

    % Index by channel of interest
    ampavgch = ampavg(chan2use,:);
    powavgch = powavg(chan2use,:);
    
    % Plot the amplitude and power frequency
    figure(2), clf
    
    subplot(2,1,1) % Top-Half
    plot(hz, ampavgch,'k','linew',2)
    set(gca, 'xlim', [0 xmax], 'ylim', [0 max(ampavgch)])
    xlabel('Frequency (Hz)')
    ylabel('PSD (microV / Hz)')
    title(['Amplitude Spectral Across Averaged Across ' num2str(trials) ' Trials for channel ' num2str(chan2use)])
    
    subplot(2,1,2) % Bottom_Half
    plot(hz, powavgch,'r','linew',2)
    set(gca, 'xlim', [0 xmax], 'ylim', [0 max(powavgch)])
    xlabel('Frequency (Hz)')
    ylabel('PSD (microV^2 / Hz)')
    title(['Power Spectral Density (PSD) Averaged Across ' num2str(trials) ' Trials for channel ' num2str(chan2use)])
    

end

       