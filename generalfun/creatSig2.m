% This function will create a signal 
% comprised of sine waves of different
% frequencies and amplitudes and trials!
% Creates a MATRIX
%
% chanNum: number of channels
% sinNum: number of unique frequencies
% srate: sampling rate (timepoints per sec)
% sigL: signal length (sec)
%
% Example:
% [Siginfo] = 


function [newsignalinfo] = creatSig2(chanNum, srate, sigL, trialNum, sinNum, noise, fig, chan2use, seed)

    % Set seed for reproducibility
    rng(seed);

    % Setting parameters
    %Create two variables to keep track of chosen Amp and Freq
    ampl = randsample(1:15, sinNum, true); % with replacement
    frex = randsample(3:0.5:40, sinNum);% without replacement

    % Time vector
    time = 0:1/srate:sigL-(1/srate);
    N = length(time);
    
    % Initialize 3D signal matrix: 1 x timepoints x trials
    newsignal = zeros(chanNum, N, trialNum);

    % loop through channels
    for chani = 1:chanNum
        % Loop through trials
        for triali = 1:trialNum
            
            % Generate signal
            signal = zeros(1, N);
            for fi = 1:length(frex)
                signal = signal + ampl(fi) * sin(2 * pi * frex(fi) * time);
            end
            
            % Add unique noise for each trial
            signal = signal + noise^2*randn(size(signal));
    
            % Store in 3D matrix (1 x timepoints x trials)
            newsignal(chani, :, triali) = signal;
        end

    end

    % Sort frequencies smallest to largers and corresponding amplitudes
    [sortfrex, sortindx] = sort(frex);
    sortampl = ampl(sortindx);

    % Store signal information
    newsignalinfo = struct(); 
    newsignalinfo.Amplitudes = floor(sortampl); 
    newsignalinfo.Frequencies = floor(sortfrex);
    newsignalinfo.SamplingRate = srate;

    newsignalinfo.FullSignalLengthSec = (N * trialNum)/srate;
    newsignalinfo.FullSignalLengthMin = (N * trialNum)/(srate*60);
    newsignalinfo.TotalPnts = N * trialNum;

    newsignalinfo.Trials = trialNum;
    newsignalinfo.TrialPnts = N;
    newsignalinfo.TrialLengthSec = N / srate;

    newsignalinfo.Signal = newsignal;


    if fig == "Yes"

        figure(1), clf
        % Plot the signal averaged across trials (ERP)
        subplot(3,1,1) % Top-Half
        plot(time, mean(newsignal(chan2use,:,:),3),'k','linew',2)
        set(gca, 'xlim', [0 sigL-(1/srate)])
        xlabel('Time (sec)')
        ylabel('Amplitude')
        title(['Trial Averaged EEG Signal Length (' num2str(sigL) ' seconds)'])
        
        subplot(3,1,2) % Middle-half
        plot(time, mean(newsignal(chan2use,:,:),3),'r','linew',2)
        set(gca, 'xlim', [1 2])
        xlabel('Time (sec)')
        ylabel('Amplitude')
        title(['Trial Averaged EEG Signal Ossilcation (1 second)'])


        % Plot the frequencies and corresponding amplitudes
        subplot(3,1,3); % Bottom subplot
        stem(sortfrex, sortampl, 'Marker', 'none','LineWidth', 2);
        set(gca,'ylim',[0 1.2* max(sortampl)])
        xlabel('Frequencies (Hz)');
        ylabel('Amplitude');
        title('Ground Truth: Generated Frequencies and Amplitudes');
    
    end
    

end

