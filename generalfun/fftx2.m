% INPUT
% signal: a sinusoid matrix (3D)
% srate: sampling rate (scalar)
% filename: file name 
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
% fcoeff: fourier coefficients (3D)
% ampavg: average amplitude across all trials (2D)
% powavg: average power across all trials (2D)
% powavg: average power across all trials in dB (2D)
% Note: -
%
% Example:
% fft_info = fftx_info = fftx2(signal, srate);

function [fftx_info] = fftx2(signal, srate, filename)

    % If signal is single then convert to double
    if isa(signal, 'single')
        signal = double(signal);
    end

    % Set up a parameter first
    srate = srate; 
    Nyquist = srate/2;
    N = size(signal,2);

    % Dimensions of the signal
    nbchan = size(signal,1);
    trials = size(signal,3);
    pnts = size(signal,2); % Redundant but its okay

    % Create the frequency vector
    hz = linspace(0,Nyquist,floor(N/2)+1);
    
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

    % Calculate the Power Spectral Density in dB/Hz
    Power_avgD = 10 * log10(Power_avg / srate);  % Convert to dB/Hz

    % Create a note variable
    Note = ['Avg Amp and Power Across ' num2str(size(signal,3)) ' Trials for Each ' num2str(size(signal,1)) ' Channels'];
    Note = [ num2str(trials) ' trials were averaged to create Avg Amp and Power for each of the '  num2str(size(signal,1)) ' Channels'];


    % Store signal information in a struct
    fftx_info = struct();
    fftx_info.filename = filename;
    fftx_info.nbchan = nbchan;
    fftx_info.trials = trials;
    fftx_info.pnts = pnts;
    fftx_info.srate = srate;
    fftx_info.xmin = 0;
    fftx_info.xmax = pnts / srate;
    fftx_info.data = signal;
    fftx_info.hz = hz;
    fftx_info.fcoeff = FourierCoeff;
    fftx_info.ampavg = Amplitude_avg;
    fftx_info.powavg = Power_avg;
    fftx_info.powavgd = Power_avgD;
    fftx_info.note = Note; 

end