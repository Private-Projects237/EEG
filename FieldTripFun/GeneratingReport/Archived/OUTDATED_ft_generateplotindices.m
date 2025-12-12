function [plotIdx] = ft_generateplotindices(folderPath)
% FT_GENERATEPLOTINDICES  Find positions where PNG suffix changes
%   plotIdx = ft_generateplotheaders(folderPath)
%   Returns vector of file indices (1-based) where a new suffix begins.

    % Get the PNG names
    dirStruct = dir(fullfile(folderPath, '*.png'));
    if isempty(dirStruct)
        error('No .png files found in: %s', folderPath);
    end
    
    pngNames = {dirStruct.name}';  % Column cell array
    
    % Extract suffix
    suffix = regexprep(pngNames, '.*_([^.]+)\.png', '$1', 'ignorecase');
    
    % Find the positions when the suffixes change
    if numel(suffix) <= 1
        plotIdx = 1;  % Only one file
    else
        % Logical vector: true where suffix differs from previous
        changeLogical = [true; ~strcmpi(suffix(2:end), suffix(1:end-1))];
        
        % Use find() to get the **positions** (1-based indices)
        plotIdx = find(changeLogical);
    end
end