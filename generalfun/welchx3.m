% INPUT
% signal: a sinusoid matrix (3D)
% srate: sampling rate (scalar)
% winsec: time down length in seconds (0.5-2)
% nOverlap_per: percentage of time window overlap (50)
% filename: file name 
% threshold: threshold in amplitude for detecting noisy EEG segment
%
% OUPUT (Structure):
% nbchan: number of channels
% trials: number of trials/segments
% pnts: time points in a trial/segment
% srate: sampling rate
% xmin: min length of a trial
% xmax: max length of a trial
% data: original signal that was input
% hz: a vector of frequencies up to Nyquist
% ampavg: average amplitude across all trials (2D)
% powavg: average power across all trials (2D)
% timewinpnts: time points for each time window
% winsec: length of the time window in seconds
% timewinover: percentage of overlap for the time windows
% Note1: -
% Note2: -
%
% Example:
% fft_info = fftx_info = fftx2(signal, srate);

function [welchx_info] = welchx3(signal, srate, winsec, nOverlap_per, filename, threshold)

    % If signal is single then convert to double
    if isa(signal, 'single')
        signal = double(signal);
    end

    % Must take all trials and put them one after another in 2D
    nbchan = size(signal,1);
    pnts = size(signal,2);
    trials = size(signal,3);
    signalr = reshape(signal, nbchan, []);

    % Set parameters for Welch's Method
    N = size(signalr,2); % NOT redundant
    winlength = winsec * srate; % Length of time window in samples
    nOverlap_prop = nOverlap_per/100;
    nOverlap = round(winlength * nOverlap_prop); % Calculate time points that correspond to the percent overalp
    winonsets = 1:nOverlap:N-winlength; % Window onset indices
    
    % Create frequency vector
    hzW = linspace(0, srate/2, floor(winlength/2) + 1);
    
    % Create Hann window
    hannw = .5 - cos(2 * pi * linspace(0, 1, winlength)) / 2;
    hannNorm = sum(hannw); % Normalization factor
    
    % Initialize amplitude spectrum
    sigampW = zeros(nbchan, length(hzW)); % Hold sums of power iterations
    sigampWN = zeros(nbchan, length(hzW)); % Hold the average of power iterations
    
    % loop through channels
    for chani = 1:nbchan

        % Create a counter to average correctly (sums of power for each
        % successful iteration)
        counter = 0;

        for wi = 1:length(winonsets)        
            % Extract data segment
            datachunk = signalr(chani, winonsets(wi):winonsets(wi)+winlength-1);

            % If segment is dirty skip the iteration
            max_abs = max(abs(datachunk(:)));
            if max_abs >= threshold
                continue; % Skip iteration since segment is too noisy
            end

            % Increase counter by 1
            counter = counter + 1;

            % Apply Hann window
            datachunkH = datachunk .* hannw;
        
            % Compute FFT and normalize
            fftLen = 2^nextpow2(winlength);
            AmplitudeW = 2 * abs(fft(datachunkH, fftLen)) / hannNorm;
        
            % Sum amplitude across segments
            sigampW(chani,:) = sigampW(chani,:) + AmplitudeW(1:length(hzW));
        
        end

        % Obtain the average now of the channel before next iteration
        sigampWN(chani,:) = sigampW(chani,:)/counter;

    end
    
    % Compute the final amplitude estimate by averaging
    % sigampWN = sigampW / length(winonsets); OUTDATED BUT WILL REMAIN
    sigpowWN = sigampWN .^ 2;

    % Average across trials
    AmplitudeW_avg = mean(sigampWN,3);
    PowerW_avg = mean(sigpowWN,3);

    % Create a note variable
    Note1 = ['The input 3D signal was reshaped to be 2D'];
    Note2 = ['Avg Amp and Power Across ' num2str(trials) ' Trials Concatenated Together for Each ' num2str(size(signal,1)) ' Channels'];
    Note3 = ['Code has been modified to not include noisy segments, thus look at QC measure to get a feel for how much data was used to calculate power'];

    % Store signal information in a struct
    welchx_info = struct();
    welchx_info.filename = filename;
    welchx_info.nbchan = nbchan;
    welchx_info.trials = trials;
    welchx_info.pnts = pnts;
    welchx_info.srate = srate;
    welchx_info.xmin = 0;
    welchx_info.xmax = pnts / srate;
    welchx_info.data = signal;
    welchx_info.hz = hzW;
    welchx_info.ampavg = AmplitudeW_avg;
    welchx_info.powavg = PowerW_avg;
    welchx_info.timewinpnts = winlength;
    welchx_info.winsec = winlength/srate;
    welchx_info.timewinover = append(num2str(nOverlap_per), "%");
    welchx_info.numtimewin = length(winonsets);
    welchx_info.note1 = Note1; 
    welchx_info.note2 = Note2;
    welchx_info.note3 = Note3;

end

