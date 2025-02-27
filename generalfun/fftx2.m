% Reports the:
% 1) FFT Hz
% 2) Fourier Coefficients
% 3) Amplitude (correct units)
% 4) Power (correct units)
%
% signal: A sinusoid wave
% srate: sampling rate
% fig: ("Yes"/"No")
% xmax: Max fz in plot
% chan2use: Pick chanl num to plot
%
% Example:
% fft_info = fftx(signal, srate, "Yes", 40);

function [fftx_info] = fftx2(signal, srate, fig, xmax, chan2use)

    % If signal is single then convert to double
    if isa(signal, 'single')
        signal = double(signal);
    end

    % Set up a parameter first
    srate = srate; 
    Nyquist = srate/2;
    N = size(signal,2);

    % Create the frequency vector
    hz = linspace(0,Nyquist,floor(N/2)+1);

    % Signal class
    signal_class = "3D-Matrix";
    
    % Calculate the Fourier Coefficient (Complex Numbers)
    FourierCoeff = fft(signal,[],2);

    % Calculate the Amplitude
    Amplitude = 2*abs(FourierCoeff)/N;
    Amplitude = Amplitude(:,1:length(hz),:);
    
    % Calculate Power
    Power = Amplitude .^ 2;

    % then average over trials
    Amplitude_avg = mean(Amplitude,3);
    Power_avg = mean(Power,3);

    % Create a note variable
    Note = ['Avg Amp and Power Across ' num2str(size(signal,3)) ' Trials for Each ' num2str(size(signal,1)) ' Channels'];

    % Store signal information in a struct
    fftx_info = struct();
    fftx_info.OrgSignal = signal;
    fftx_info.Class = signal_class;
    fftx_info.Hz = hz;
    fftx_info.FourierCoeff = FourierCoeff;
    fftx_info.Amplitude_avg = Amplitude_avg;
    fftx_info.Power_avg = Power_avg;
    fftx_info.trialLength_sec = N/srate;
    fftx_info.Note = Note; 

     
    if fig == "Yes"
        % Plot the amplitude and power frequency
        figure(3), clf
        
        subplot(2,1,1) % Top-Half
        plot(hz, Amplitude_avg(chan2use,:),'k','linew',2)
        set(gca, 'xlim', [0 xmax])
        xlabel('Frequency (Hz)')
        ylabel('Amplitude')
        title(['Avg Amplitude Spectral Density (ASD) Across ' num2str(size(signal,3)) ' Trials for channel ' num2str(chan2use)])
        
        subplot(2,1,2) % Bottom_Half
        plot(hz, Power_avg(chan2use,:),'r','linew',2)
        set(gca, 'xlim', [0 xmax])
        xlabel('Frequency (Hz)')
        ylabel('Power')
        title(['Avg Power Spectral Density (PSD) Across ' num2str(size(signal,3)) ' Trials for channel ' num2str(chan2use)])
    
    end

end