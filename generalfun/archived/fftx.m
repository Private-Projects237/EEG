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

    % If signal is single then convert to double
    if isa(signal, 'single')
        signal = double(signal);
    end

    % Set up a parameter first
    srate = srate; 
    Nyquist = srate/2;
    N = length(signal);

    % Create the frequency vector
    hz = linspace(0,Nyquist,floor(N/2)+1);

    % Check for vector or 3D matrix
    if ndims(signal) == 2
    
        % Signal class
        signal_class = "Vector";

        % Calculate the Fourier Coefficient (Complex Numbers)
        FourierCoeff = fft(signal);
        
        % Calculate the Amplitude
        Amplitude = 2*abs(FourierCoeff)/N;
        Amplitude = Amplitude(1:length(hz)); % Reduce length by half
        
        % Calculate the Power
        Power = Amplitude .^ 2;

        % Create a note variab;e
        Note = ['Amp and Pow for a vector'];
    
    elseif ndims(signal) == 3

        % Signal class
        signal_class = "3D-Matrix";
        
        % Calculate the Fourier Coefficient (Complex Numbers)
        FourierCoeff = fft(signal,[],2);

        % Calculate the Amplitude
        Amplitude = 2*abs(FourierCoeff)/N;
        Amplitude = Amplitude(1:length(hz));
        
        % Calculate Power
        Power = Amplitude .^ 2;

        % then average over trials
        Amplitude = mean(Amplitude,3);
        Power = mean(Power,3);

        % Create a note variable
        Note = ['Avg Amp and Power for ' num2str(size(signal,3)) ' trials'];
        
    else 
        error('Signal must be a vector or a 3D matrix');

    end

    % Store signal information in a struct
    fftx_info = struct();
    fftx_info.SigDim = size(signal);
    fftx_info.Class = signal_class;
    fftx_info.Hz = hz;
    fftx_info.FourierCoeff = FourierCoeff;
    fftx_info.Amplitude = Amplitude;
    fftx_info.Power = Power;
    fftx_info.Note = Note; 

     
    if fig == "Yes"
        % Plot the amplitude and power frequency
        figure(3), clf
        
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