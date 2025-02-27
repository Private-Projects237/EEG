% INPUT
% newsig_info: output from creatSig2()`
% chan2use: choose channel to plot
% xmax: x-axis max cut-off
%
% OUPUT (Plots):
% Plot 1: Avg Amplitudes Across Trials in Time Domain
% Plot 2: Avg Amplitudes Across Trials in 1 second
% Plot 3: Respective Amplitudes and Frequencies that make up the signal
%
% Example:
% plot_CreatSig2(newsig_info,1,30)

function plot_CreatSig2(newsig_info, chan2use, xmax)


    % Extract the hz, amplitude avg, and power spectral density
    data = newsig_info.data;
    amp = newsig_info.amp;
    frex = newsig_info.frex;
    srate = newsig_info.srate;
    pnts = newsig_info.pnts;

    % Index by channel of interest
    datach = data(chan2use,:,:);

    % Calculate time (sec)
    siglensec = pnts / srate;
    t = 0:1/srate:siglensec-(1/srate);

    figure(1), clf
    % Plot the signal averaged across trials (ERP)
    subplot(3,1,1) % Top-Half
    plot(t, mean(datach,3),'k','linew',2)
    xlabel('Time (sec)')
    ylabel('Amplitude')
    title(['Trial Averaged EEG Signal Length (' num2str(siglensec) ' seconds)'])
    
    subplot(3,1,2) % Middle-half
    plot(t, mean(datach,3),'r','linew',2)
    set(gca, 'xlim', [1 2])
    xlabel('Time (sec)')
    ylabel('Amplitude')
    title(['Trial Averaged EEG Signal Ossilcation (1 second)'])


    % Plot the frequencies and corresponding amplitudes
    subplot(3,1,3); % Bottom subplot
    stem(frex, amp, 'Marker', 'none','LineWidth', 2);
    set(gca,'ylim',[0 1.2* max(amp)])
    xlabel('Frequencies (Hz)');
    ylabel('Amplitude');
    title('Ground Truth: Generated Frequencies and Amplitudes');
    
end
    