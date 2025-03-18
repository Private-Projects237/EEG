% INPUT: 
% EEG: EEG struct
% segmentLength: time window in seconds (ex: 5)
% thresholdMultiplier: the threshold for a noisy channel (ex: 2; 3; 5)
%
% OUTPUT: 
% badChannels: A cell array with channels that were identified as noisy
% that should be interpolated
% badChannelsNum: The bad channel number
%
% Description: This function was created to identify the index of noisy
% channels in an EEG struct. It does this by segmenting each channel by a
% desired time window and then calculating the standard deviation for that
% segment. This is done for all segments and an average SD across segments
% is calculated for each channel. The median of these average SD is
% obtained, and any channels that deviates highly from this median, set by
% the thresholdMultiplier will be indexed for removal. 

function [badChannels, badChannelsNum] = detect_noisy_channels_segmented(EEG, segmentLength, thresholdMultiplier)

    % Set up parameters for indexing EEG segments
    fs = EEG.srate; 
    segmentSamples = segmentLength * fs;  % Convert segment length to samples
    numChans = size(EEG.data, 1);
    numSegments = floor(size(EEG.data, 2) / segmentSamples);  % Number of full segments
    
    % Initialize array to store per-segment SD
    segmentSD = zeros(numChans, numSegments);

    % Loop through segments
    for seg = 1:numSegments

        % Segment data into time windows
        startIdx = (seg - 1) * segmentSamples + 1;
        endIdx = seg * segmentSamples;
        segmentData = EEG.data(:, startIdx:endIdx);

        % Compute SD for this segment
        segmentSD(:, seg) = std(segmentData, [], 2);
    end

    % Average SD across all segments for each channel
    avgSD = mean(segmentSD, 2);

    % Compute global median SD across all channels
    medianSD = median(avgSD);

    % Define bad channel threshold
    threshold = thresholdMultiplier * medianSD;

    % Identify bad channels (those with higher SD than threshold)
    badChannelsNum = find(avgSD > threshold);

    % Get bad channel names and their index
    badChannels = {EEG.chanlocs(badChannelsNum).labels};

    % Display results
    disp('Bad channels detected using segmented SD method:');
    disp(badChannels);

end