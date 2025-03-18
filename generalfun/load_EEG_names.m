% INPUT: 
% EEG_dir: directory to where the EEG files are (ex: 'C:/user/EEG/RAW_DATA/)
% EEG_type: the extension of the eeg file (ex: .vmrk)
% full: gives you the full filename (ex: 'yes';'no')
%
% OUTPUT
% fullEEGfiles: the fullpathway name of the EEG file
%
% Description: This fun
function [EEGFileNames] = load_EEG_names(EEG_dir, EEG_type, full)

    % Load in the information (struct)
    EEG_dir_info = dir(EEG_dir);

    % Extract the names of the EEG files in this directory
    EEGFileNames = {EEG_dir_info(contains({EEG_dir_info.name}, EEG_type)).name};

    if strcmp(full, 'yes')       
        % Merge the full pathway and the EEG filenames together
        EEGFileNames = append(EEG_dir, EEG_filenames);
    end
end