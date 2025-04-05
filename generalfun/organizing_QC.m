% INPUT: 
% EEG_csv_save_path: The location where your EEG QC CSV are saved
% fileExten: write in the extension of the file (ex 'dry.csv')
%
% Description: Reads in EEG QC CSV files and then binds them into a table
% 
%
function combinedTable = organizing_QC(EEG_csv_save_path, fileExten)

    % Extract the files from that location
    filenames_csv = load_EEG_names(EEG_csv_save_path, 'dry.csv', 'yes');

    % Create an empty table
    combinedTable = table();

    % Loop through each file
    for i = 1:length(filenames_csv)
        % Read the current file into a table
        % Using readtable - adjust based on your file format
        currentTable = readtable(filenames_csv{i});
        
        % Vertically concatenate with the combined table
        % Using vertcat or [ ; ] notation
        combinedTable = [combinedTable; currentTable];
    end

end