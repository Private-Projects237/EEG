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
%
% Example:
% fft_info = fftx(signal, srate, "Yes", 40);

function [fftx_info] = fftx(signal, srate, fig, xmax)

    % Set up a parameter first
    srate = srate; 
    Nyquist = srate/2;
    N = length(signal);

    % Create the frequency vector
    hz = linspace(0,Nyquist,floor(N/2)+1);


    % Calculate the Fourier Coefficient (Complex Numbers
    FourierCoeff = fft(signal);
    
    % Calculate the Amplitude
    Amplitude = 2*abs(FourierCoeff)/N;
    Amplitude = Amplitude(1:length(hz)); % Reduce length by half
    
    % Calculate the Power
    Power = Amplitude .^ 2;

    
    % Store signal information in a struct
    fftx_info = struct();
    fftx_info.Hz = hz;
    fftx_info.FourierCoeff = FourierCoeff;
    fftx_info.Amplitude = Amplitude;
    fftx_info.Power = Power;
    
    
    if fig == "Yes"
        % Plot the amplitude and power frequency
        figure(2), clf
        
        subplot(2,1,1) % Top-Half
        plot(hz,Amplitude(1:length(hz)),'k','linew',2)
        set(gca, 'xlim', [0 xmax])
        xlabel('Frequency (Hz)')
        ylabel('Amplitude')
        title('Amplitude Spectral Density (ASD)')
        
        subplot(2,1,2) % Bottom_Half
        plot(hz,Power(1:length(hz)),'r','linew',2)
        set(gca, 'xlim', [0 xmax])
        xlabel('Frequency (Hz)')
        ylabel('Power')
        title('Power Spectral Density (PSD)')
    
    end

end