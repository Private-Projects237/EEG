% Reports the:
% 1) Welch Hz  
% 2) Amplitude (correct units)
% 3) Power (correct units)
% 4) Number of Time Windows
% 5) Window length chosen
%
% signal: A 3D Matrix
% srate: sampling rate
% winsec = time window in seconds (scalar)
% nOverlap_per = percentage (0-100)
% fig: ("Yes"/"No")
% xmax: Max fz in plot
% chan2use: Pick chanl num to plot
%
% Example:
% welch_info = welchx(signal, srate, 1, 50, "Yes", 30);

function [welchx_info] = welchx2(signal, srate, winsec, nOverlap_per, fig, xmax, chan2use)

    % If signal is single then convert to double
    if isa(signal, 'single')
        signal = double(signal);
    end

    % Must take all trials and put them one after another in 2D
    trialNum = size(signal,3);
    ChanNum = size(signal,1);
    signal = reshape(signal, ChanNum, []);

    % Set parameters for Welch's Method
    N = size(signal,2);
    signal = signal;
    winlength = winsec * srate; % Length of time window in samples
    nOverlap_prop = nOverlap_per/100;
    nOverlap = round(srate * nOverlap_prop); % Calculate time points that correspond to the percent overalp
    winonsets = 1:nOverlap:N-winlength; % Window onset indices

    % Obtain other parameters
    chanNum = size(signal,1);
    signal_class = "3D-Matrix";
    
    % Create frequency vector
    hzW = linspace(0, srate/2, floor(winlength/2) + 1);
    
    % Create Hann window
    hannw = .5 - cos(2 * pi * linspace(0, 1, winlength)) / 2;
    hannNorm = sum(hannw); % Normalization factor
    
    % Initialize amplitude spectrum
    sigampW = zeros(chanNum, length(hzW));
    
    % loop through channels
    for chani = 1:chanNum

        for wi = 1:length(winonsets)
        
            % Extract data segment
            datachunk = signal(chani, winonsets(wi):winonsets(wi)+winlength-1);
        
            % Apply Hann window
            datachunkH = datachunk .* hannw;
        
            % Compute FFT and normalize
            fftLen = 2^nextpow2(winlength);
            AmplitudeW = 2 * abs(fft(datachunkH, fftLen)) / hannNorm;
        
            % Sum amplitude across segments
            sigampW(chani,:) = sigampW(chani,:) + AmplitudeW(1:length(hzW));
        
        end

    end
    
    % Compute the final amplitude estimate by averaging
    sigampWN = sigampW / length(winonsets);
    sigpowWN = sigampWN .^ 2;

    % Average across trials
    AmplitudeW_avg = mean(sigampWN,3);
    PowerW_avg = mean(sigpowWN,3);

    % Create a note variable
    Note = ['Avg Amp and Power Across ' num2str(trialNum) ' Trials Concatenated Together for Each ' num2str(size(signal,1)) ' Channels'];

    % Store signal information in a struct
    welchx_info = struct();
    welchx_info.OrgSignal = signal;
    welchx_info.Class = signal_class;
    welchx_info.Hz = hzW;
    welchx_info.Amplitude_avg = AmplitudeW_avg;
    welchx_info.Power_avg = PowerW_avg;
    welchx_info.SamplingRate = srate;
    welchx_info.TimeWinPnts = winlength;
    welchx_info.WinSec = winlength/srate;
    welchx_info.TimeWinOver = append(num2str(nOverlap_per), "%");
    welchx_info.NumTimeWin = length(winonsets);
    welchx_info.Note = Note; 


    
    if fig == "Yes"
        % Plot results
        figure(4), clf
        
        subplot(2,1,1) % Top-Half
        plot(hzW, AmplitudeW_avg(chan2use,:), 'k', 'LineWidth', 2)
        set(gca, 'xlim', [0 xmax])
        xlabel('Frequency (Hz)')
        ylabel('Amplitude')
        title(['Avg Amplitude Spectral Density (ASD) Across ' num2str(size(signal,3)) ' Trials for channel ' num2str(chan2use)])
        
        subplot(2,1,2) % Bottom-Half
        plot(hzW, PowerW_avg(chan2use,:), 'r', 'LineWidth', 2)
        set(gca, 'xlim', [0 xmax])
        xlabel('Frequency (Hz)')
        ylabel('Power')
        title(['Avg Power Spectral Density (PSD) Across ' num2str(size(signal,3)) ' Trials for channel ' num2str(chan2use)])

    end


end
