function logLines = struct2log(s, parentField)
    if nargin < 2
        parentField = '';
    end
    fields = fieldnames(s);
    logLines = {};
    for i = 1:numel(fields)
        fld = fields{i};
        val = s.(fld);
        if isstruct(val)
            % Recursive call for nested structs
            nestedLines = struct2log(val, fullfile(parentField, fld));
            logLines = [logLines; nestedLines]; %#ok<AGROW>
        else
            % Convert numeric arrays or cell arrays to readable strings
            if isnumeric(val)
                valStr = mat2str(val);
            elseif iscell(val)
                valStr = strjoin(string(val), ', ');
            elseif islogical(val)
                valStr = mat2str(val);
            else
                valStr = char(val);
            end
            % Create log line
            logLines{end+1,1} = sprintf('%s: %s', fullfile(parentField, fld), valStr); %#ok<AGROW>
        end
    end
end