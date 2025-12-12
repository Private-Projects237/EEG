% INPUT
% EEG = The EEG structure
% Threshold = The amplitude threshold where if exceeds it's considered bad
% Seg_Sec = The length of the segments that it will create

% OUTPUT (SegmentQc Structure):
% SegmentQc.n_segments = The total number of EEG segments
% SegmentQc.n_goodsegments = The total number of good EEG segments
% SegmentQc.n_badsegments = The total number of bad EEG segments
% SegmentQc.propRemaining = The proportion of segments that are good

% Description: EEG data will be segmented by a specified amount in seconds.
% These segments will then be inspected one by one to identify if there are
% amplitudes there larger than we want. If that is the case, those segments
% will be deleted and the remaining good segments will be joined together.
% Additionally, information related to the number of segments generated,
% the number of good vs bad segments, and the proportion of segments that
% are good will be returned with the EEG data. 

function SegmentQc = seg_reject_num(EEG, Threshold, Seg_Sec, Overlap)
    
    % Number of samples per segment (time points)
    segment_length = round(Seg_Sec * EEG.srate);
    
    % Total number of samples in the data (along the time axis)
    n_samples = size(EEG.data, 2);  
    
    % Calculate step size based on overlap percentage
    overlap_fraction = Overlap / 100;
    step_size = round(segment_length * (1 - overlap_fraction));
    
    % Ensure step_size is at least 1 to avoid infinite loops
    if step_size < 1
        step_size = 1;
    end
    
    % Number of segments with overlap
    n_segments_overlap = floor((n_samples - segment_length) / step_size) + 1;
    
    % Number of non-overlapping segments
    n_segments = floor(n_samples / segment_length);
    
    % Set up empty variables for the for loop
    good_count = 0;
    bad_count = 0;
    good_indices = [];
    bad_indices = [];
    
    for i = 1:n_segments_overlap
        start_idx = (i-1) * step_size + 1;
        end_idx = min(start_idx + segment_length - 1, n_samples);
        
        % Extract segment (works for vector or matrix)
        segment = EEG.data(:, start_idx:end_idx);
    
        % Compute max absolute value across all channels (if multi-channel)
        max_abs = max(abs(segment(:)));  % Flatten to get global max abs
        
        % Identify good and bad segments based on the specified threshold
        if max_abs < Threshold
            good_count = good_count + 1;
            good_indices(end+1) = i;  
        else
            bad_count = bad_count + 1;
            bad_indices(end+1) = i; 
        end
    end
    
    % Create a structure
    SegmentQc = struct();
    
    % Add QC measures into the struct
    SegmentQc.n_segments = n_segments;
    SegmentQc.overlapPercent = Overlap; 
    SegmentQc.n_segmentsOverlap = n_segments_overlap;
    SegmentQc.n_goodsegments = good_count;
    SegmentQc.n_badsegments = bad_count;
    SegmentQc.propRemaining = round(good_count/n_segments_overlap,2);
    
end

