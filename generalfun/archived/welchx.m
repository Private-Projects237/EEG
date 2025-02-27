% Reports the:
% 1) Welch Hz  
% 2) Amplitude (correct units)
% 3) Power (correct units)
% 4) Number of Time Windows
% 5) Window length chosen
%
% signal: A sinusoid wave
% srate: sampling rate
% winsec = time in seconds (scalar)
% nOverlap = percentage (0-100)
% fig: ("Yes"/"No")
% xmax: Max fz in plot
%
% Example:
% welch_info = welchx(signal, srate, 1, 50, "Yes", 30);

function [welchx_info] = welchx(signal, srate, winsec, nOverlap_per, fig, xmax)

    % Set parameters for Welch's Method
    N = length(signal);
    signal = signal;
    winlength = winsec * srate; % Length of time window in samples
    nOverlap_prop = nOverlap_per/100;
    nOverlap = round(srate * nOverlap_prop); % Calculate time points that correspond to the percent overalp
    winonsets = 1:nOverlap:N-winlength; % Window onset indices
    
    % Create frequency vector
    hzW = linspace(0, srate/2, floor(winlength/2) + 1);
    
    % Create Hann window
    hannw = .5 - cos(2 * pi * linspace(0, 1, winlength)) / 2;
    hannNorm = sum(hannw); % Normalization factor
    
    % Initialize amplitude spectrum
    sigampW = zeros(1, length(hzW));
    
    for wi = 1:length(winonsets)
    
        % Extract data segment
        datachunk = signal(winonsets(wi) : winonsets(wi) + winlength - 1);
    
        % Apply Hann window
        datachunkH = datachunk .* hannw;
    
        % Compute FFT and normalize
        AmplitudeW = 2 * abs(fft(datachunkH)) / hannNorm;
    
        % Sum amplitude across segments
        sigampW = sigampW + AmplitudeW(1:length(hzW));
    
    end
    
    % Compute the final amplitude estimate by averaging
    sigampWN = sigampW / length(winonsets);
    sigpowWN = sigampWN .^ 2;

    % Store signal information in a struct
    welchx_info = struct();
    welchx_info.Hz = hzW;
    welchx_info.Amplitude = sigampWN;
    welchx_info.Power = sigpowWN;
    welchx_info.TimeWinlen = winlength; 
    welchx_info.TimeWinOver = append(num2str(nOverlap_per), "%");
    welchx_info.NumTimeWin = length(winonsets);

    
    if fig == "Yes"
        % Plot results
        figure(3), clf
        
        subplot(2,1,1) % Top-Half
        plot(hzW, sigampWN, 'k', 'LineWidth', 2)
        set(gca, 'xlim', [0 xmax])
        xlabel('Frequency (Hz)')
        ylabel('Amplitude')
        title('Amplitude Spectral Density (ASD)')
        
        subplot(2,1,2) % Bottom-Half
        plot(hzW, sigpowWN, 'r', 'LineWidth', 2)
        set(gca, 'xlim', [0 xmax])
        xlabel('Frequency (Hz)')
        ylabel('Power')
        title('Power Spectral Density (PSD)')

    end


end