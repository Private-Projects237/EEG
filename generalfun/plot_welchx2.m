% INPUT
% welch_info: output from `welchx2()`
% chan2use: choose channel to plot
% xmax: x-axis max cut-off

% OUPUT (Plots):
% Plot 1: Avg Amplitudes for frequencies in one channel
% Plot 2: Avg Power for frequencies in one channel


function plot_welchx2(welch_info, chan2use, xmax)

    % Extract the hz, amplitude avg, and power spectral density
    hz = welch_info.hz;
    ampavg = welch_info.ampavg;
    powavg = welch_info.powavg;
    trials = welch_info.trials

    % Index by channel of interest
    ampavgch = ampavg(chan2use,:);
    powavgch = powavg(chan2use,:);

    % Plot results
    figure(4), clf
    
    subplot(2,1,1) % Top-Half
    plot(hz, ampavgch, 'k', 'LineWidth', 2)
    set(gca, 'xlim', [0 xmax], 'ylim', [0 max(ampavgch)])
    xlabel('Frequency (Hz)')
    ylabel('PSD (microV / Hz)')
    title(['Amplitude Spectral Across Averaged Across ' num2str(trials) ' Trials for channel ' num2str(chan2use)])

    subplot(2,1,2) % Bottom-Half
    plot(hz, powavgch, 'r', 'LineWidth', 2)
    set(gca, 'xlim', [0 xmax], 'ylim', [0 max(powavgch)])
    xlabel('Frequency (Hz)')
    ylabel('PSD (microV^2 / Hz)')
    title(['Power Spectral Density (PSD) Averaged Across ' num2str(trials) ' Trials for channel ' num2str(chan2use)])
    
end