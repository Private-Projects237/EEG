% This function will create a signal 
% comprised of sine waves of different
% frequencies and amplitudes.
%
% sinNum: number of unique frequencies
% fzStart: lowest Hz
% fzStop: largest Hz
% srate: sampling rate (timepoints per sec)
% sigL: signal length (sec)
% fig: ("Yes"/"No")
% seed: seed number
%
% Example:
% [signal, info] = creatSig(8, 3, 30, srate, 12, "No", 123)

function [newsignal, newsignalinfo] = creatSig(sinNum,fzStart, fzStop, srate, sigL, fig, seed)

    % Set seed
    rng(seed);

    % Setting parameters
    fz_vec = fzStart:fzStop;
    amp_vec = 3:16;
    frex = fz_vec(randperm(length(fz_vec), sinNum));
    ampl =  amp_vec(randperm(length(amp_vec), sinNum));

    % Setting up more parameters
    srate = srate; 
    sigL = sigL;
    time = 0:1/srate:sigL-(1/srate);

    % Creating the sine wave
    newsignal = zeros(size(time));

    for fi=1:length(frex)

        % Create a sine wave
        sine_wave = ampl(fi) * sin(2*pi*frex(fi)*time);

        % Add created sine waves
        newsignal = newsignal + sine_wave;

    end

    % Introduce some noise
    newsignal = newsignal + max(ampl)/2 * randn(size(newsignal));

    % Sort frequencies smallest to largers and corresponding amplitudes
    [sortfrex, sortindx] = sort(frex);
    sortampl = ampl(sortindx);

    % Store signal information in a struct
    newsignalinfo = struct();
    newsignalinfo.Frequencies = sortfrex;
    newsignalinfo.Amplitudes = sortampl;
    newsignalinfo.SamplingRate = srate;
    newsignalinfo.Pnts = length(time);
    newsignalinfo.Sec = newsignalinfo.Pnts/ newsignalinfo.SamplingRate;
    
    % Plot if requested
    if fig == "Yes"
        fig(1), clf
        subplot(2,1,1) % Top-Half
        plot(time, newsignal);
        title(['Generated Signal across ' num2str(sigL) ' sec']);
        xlabel('Time (s)');
        ylabel('Amplitude');

        subplot(2,1,2) % Bottom-Half
        plot(time, newsignal);
        set(gca, 'xlim',[2 3])
        title('Generated Signal across 1 sec');
        xlabel('Time (s)');
        ylabel('Amplitude');

    end

end