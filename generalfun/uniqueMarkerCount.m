function [combinedString] = uniqueMarkerCount(EEG) 
    % Extract the unique markers in the EEG
    unique_markers = unique({EEG.event.type});
    
    % Calculate the Frequency of each unique marker in the data
    current_freq = [];
    
    for ii = 1:length(unique_markers)
        current_freq(ii) = sum(strcmp({EEG.event.type}, unique_markers{ii}));
    end
    
    % Save this information as a cell array
    pairCell = cellfun(@(lbl,n) sprintf('%s: %d', strtrim(lbl), n), ...
                       unique_markers, num2cell(current_freq), ...
                       'UniformOutput', false);
    
    % Combine this information together
    combinedString = strjoin(pairCell, ';');

end