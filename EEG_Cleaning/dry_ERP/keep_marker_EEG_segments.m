% INPUT: 
% EEG: The EEG struct of the file you are working with
% markerNames: A cell array with the markers of interest
% markerLatThresh: The latency threshold after marker presentation that indicates 
% when EEG data will start to be deleted if another marker is not detected
% baselineLat: The EEG segment length (in milliseconds) required for the first marker of
% interest
% postStiLat: The EEG segment length (in milliseconds) required for the the
% end of the last marker
%
% Description: This code will keep only EEG data that has markers of
% interest and delete everything else. It will produce an EEG struct with
% these changes,

function[EEG_merged] = keep_marker_EEG_segments(EEG, markerNames, markerLatThresh, baselineLat, postStiLat)

    % === Identify the latency of the first and last meaningful marker
    initial_idx = find(ismember({EEG.event.type}, markerNames), 1, 'first');
    final_idx = find(ismember({EEG.event.type}, markerNames), 1, 'last');
    initial_pnts = EEG.event(initial_idx).latency;
    final_pnts = EEG.event(final_idx).latency;

    % === Correct latency for first and final makers
    sampling_rate_milli = EEG.srate/1000;
    initial_pnts_corrected = initial_pnts - (baselineLat * sampling_rate_milli);
    final_pnts_corrected = final_pnts + (postStiLat * sampling_rate_milli);

    % === In case the correction cannot be done due to short EEG segments
    if (initial_pnts_corrected <= 0)
         initial_idx = find(ismember({EEG.event.type}, markerNames), 2, 'first');
         second_indx = initial_idx(2);
         initial_pnts = EEG.event(second_indx).latency;
         initial_pnts_corrected = initial_pnts - (baselineLat * sampling_rate_milli);
    end

    if (final_pnts_corrected > size(EEG.data,2))
         final_pnts = find(ismember({EEG.event.type}, markerNames), 2, 'last');
         first_indx = initial_idx(1);
         final_pnts = EEG.event(first_indx).latency;
         final_pnts_corrected = final_pnts - (baselineLat * sampling_rate_milli);
    end

    % === Identify latency boundaries to keep EEG data with markers   
    MarkerLatBoundaries = [];
    iii = 1;

    for ii = 1:length(EEG.event)
        if ii + 1 == length(EEG.event)
            break; % Exit the for loop
        end
        if ismember(EEG.event(ii).type, markerNames)
            % Check the latency difference between markers
            lat_diff = EEG.event(ii+1).latency - EEG.event(ii).latency;
            
            if lat_diff > markerLatThresh % If the difference is great, then save that info
                MarkerLatBoundaries(iii) = EEG.event(ii).latency;
                MarkerLatBoundaries(iii+1) = EEG.event(ii+1).latency - (baselineLat * sampling_rate_milli); % Introduce baseline EEG
                iii = iii + 2;
            end
        end
    end

    % === Introduce the first and last marker latencies into
    % the MarkerLatBoundaries vector
    full_MarkerLatBoundaries = [initial_pnts_corrected MarkerLatBoundaries final_pnts_corrected];
    
    % === Keep the data in between the marker latencies
    EEG_segments = {}; % Create an empty structure to keep EEG segments with marker info
    for ii = 1:(length(full_MarkerLatBoundaries)/2)
        EEG_segments{end+1} = pop_select(EEG, 'point', [full_MarkerLatBoundaries(ii*2-1), full_MarkerLatBoundaries(ii*2)]);  
    end 

    % === Merge all EEG segments with marker info
    EEG_merged = EEG_segments{1};        % start with the first
    for k = 2:numel(EEG_segments)
        EEG_merged = pop_mergeset(EEG_merged, EEG_segments{k}, 1);  % 1 = shift events
    end

end