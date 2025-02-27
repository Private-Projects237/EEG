
% This function will create a *non stationary* 
% signal comprised of sine waves of different
% frequencies and amplitudes and trials!
% Creates a MATRIX
%
% WARNING: sigL / transf_sec < 75
%
% chanNum: desired number of channels
% srate: desired sampling rate
% sigL: desired signal length for a trial (sec)
% trialNum: desired num of trials
% transf_sec: Seconds until signal drastically changes
% sinNum: desired number of unique frequencies
% noise: desired noise in signal
% fig: ("Yes"/"No")
% chan2use: channel to plot
% seed: set seed
%
% Example:
% [Siginfo] = 


function [NonStatSiginfo] = creatSig3(chanNum, srate, sigL, trialNum, transf_sec, sinNum, noise, fig, chan2use, seed)

    % Set seed for reproducibility
    rng(seed);
    
    % parameters to set
    % sigL = 120; % Length of signal in seconds
    % transf_sec = 5; % When to change sine wave
    
    
    % Number of chunks
    t = 0:1/srate:sigL-(1/srate);  
    N = length(t);  % Total number of time points
    transf = sigL/transf_sec;
    chunk_idx = floor(N / transf);  % time points for a data chunk
    
    % Create a matrix for the new signal
    % It will contain data in the middle and each 
    newSig = zeros(1,chunk_idx,transf);

    %Create two variables to keep track of chosen Amp and Freq
    ampl = randsample(1:15, transf, true); % with replacement
    frex = randsample(3:0.5:40, transf);% without replacement
    
    % Obtain transf number of data chunks
    for ci = 1:transf
    
        % obtain the starting index of the chunk
        start_idx = (ci - 1) * chunk_idx + 1;  
        end_idx = min(ci * chunk_idx, N); 
        t_chunk = t(start_idx:end_idx); 
    
        % Apply random phase shift to most chunks (e.g., 80% probability)
        if rand < 0.8
            randPhase = 2 * pi * rand; % Random phase shift between 0 and 2π
        else
            randPhase = 0; % No phase shift for some chunks
        end
    
        % Every 5th iteration, shift the mean up or down
        offset = 0; % Default no shift
        if mod(ci, 4) == 0
            offset = randi([-5, 5]); % Random mean shift
        end
    
        % Create the signal with mean shift and phase shift
        newSig(1,:, ci) = ampl(ci) * sin(2*pi*frex(ci)*t_chunk + randPhase) + offset;
    
        % Apply taper every 3rd iteration
        if mod(ci, 3) == 0
            newSig(1,:, ci) = newSig(1,:, ci) .* hann(length(t_chunk))';
        end
    
    end



    
    % Concatenate the trials
    newSigr = reshape(newSig, 1, []);

    % Create a new amplitude and frequency vector for the sine waves we are
    % adding across the whole signal
    ampl2 = [1 2];
    frex2 = [1 2];
    
    % Add two slow sine waves to the signal to smooth it out more
    newSigr = newSigr + ampl2(1) * sin(2*pi*frex2(1)*t);
    newSigr = newSigr + ampl2(2) * sin(2*pi*frex2(2)*t);
    
    % Duplicate the data to create desired number of channels and trials
    newSigl = zeros(chanNum, length(newSigr), trialNum);
    for chani =1:chanNum
    
        for triali = 1:trialNum
    
            % duplicate the data into the size of the signal specified
            newSigl(chani,:,triali) = newSigr;
        
        end
    end

    % Introduce the amplide and frequency information into ampl and frex
    ampl = [ampl2 ampl];
    frex = [frex2 frex];
    
    % Sort frequencies smallest to largers and corresponding amplitudes
    [sortfrex, sortindx] = sort(frex);
    sortampl = ampl(sortindx);

    % Store signal information
    NonStatSiginfo = struct(); 
    NonStatSiginfo.Amplitudes = floor(sortampl); 
    NonStatSiginfo.Frequencies = floor(sortfrex);
    NonStatSiginfo.SamplingRate = srate;

    NonStatSiginfo.FullSignalLengthSec = (N * trialNum)/srate;
    NonStatSiginfo.FullSignalLengthMin = (N * trialNum)/(srate*60);
    NonStatSiginfo.TotalPnts = N * trialNum;
    
    NonStatSiginfo.Trials = trialNum;
    NonStatSiginfo.TrialPnts = N;
    NonStatSiginfo.TrialLengthSec = N / srate;
    
    NonStatSiginfo.SignalTransSec = transf_sec;
    NonStatSiginfo.Signal = newSigl;

    if fig == "Yes"
    
        figure(1), clf
        % Plot the graph
        subplot(3,1,1) % Top-Half
        plot(t,mean(newSigl(chanNum,:,:),3))
        set(gca, 'xlim', [0 sigL])
        xlabel('Time (sec)')
        ylabel('Amplitude')
        title(['Trial Averaged EEG Signal Length (' num2str(sigL) ' seconds)'])


        % Plot the first two seconds
        subplot(3,1,2) % Middle-half
        plot(t,mean(newSigl(chanNum,:,:),3))
        set(gca, 'xlim', [1 2])
        xlabel('Time (sec)')
        ylabel('Amplitude')
        title(['Trial Averaged EEG Signal Ossilcation (2 seconds)'])


        % Plot the frequencies and corresponding amplitudes
        subplot(3,1,3); % Bottom subplot
        stem(sortfrex, sortampl, 'Marker', 'none','LineWidth', 2); 
        set(gca,'ylim',[0 1.2* max(sortampl)])
        xlabel('Frequencies (Hz)');
        ylabel('Amplitude');
        title('Ground Truth: Generated Frequencies and Amplitudes');


    end

end