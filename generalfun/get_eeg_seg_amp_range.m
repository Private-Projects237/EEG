  % GETEEGSEGMENTAMPLITUDERANGE - Computes average amplitude range across EEG segments
    % Inputs:
    %   EEG: EEGLAB struct or matrix [channels x time] (raw or cleaned)
    %   segmentLengthSec: Length of each segment in seconds (e.g., 1, 5)
    % Output:
    %   avgAmplitudeRange: Average amplitude range across segments in μV

    % Extract data and sampling rate

    
function avgAmplitudeRange = get_eeg_seg_amp_range(EEG, segmentLengthSec)
  
    if isstruct(EEG) && isfield(EEG, 'data')
        eegData = EEG.data; % [channels x time]
        srate = EEG.srate; % Sampling rate in Hz
    elseif isnumeric(EEG)
        error('If EEG is a matrix, sampling rate must be provided via EEGLAB struct');
    else
        error('Invalid EEG input: Must be an EEGLAB struct');
    end

    % Calculate segment length in samples
    segmentLengthSamples = round(segmentLengthSec * srate);
    nChannels = size(eegData, 1);
    nSamples = size(eegData, 2);

    % Determine number of full segments
    nSegments = floor(nSamples / segmentLengthSamples);

    % If no full segments, use the whole dataset as one segment
    if nSegments == 0
        warning('Data shorter than segment length; using full dataset as one segment');
        segmentRanges = max(eegData(:)) - min(eegData(:));
    else
        % Preallocate segment ranges
        segmentRanges = zeros(nSegments, 1);

        % Compute range for each segment
        for i = 1:nSegments
            startIdx = (i - 1) * segmentLengthSamples + 1;
            endIdx = i * segmentLengthSamples;
            segmentData = eegData(:, startIdx:endIdx); % All channels for this segment
            segmentRanges(i) = max(segmentData(:)) - min(segmentData(:));
        end
    end

    % Compute average range
    avgAmplitudeRange = round(mean(segmentRanges),2);

    % Display result
    fprintf('Average Segment Amplitude Range (%.1f-sec segments): %.2f μV\n', ...
        segmentLengthSec, avgAmplitudeRange);
end