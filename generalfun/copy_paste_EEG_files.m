% INPUT: 
% EEG_type: Specific types of files within a cell array (ex: {'.eeg', '.vhdr', '.vmrk'})
% EEG_Pathway: The location where the RAW EEG files are located to copy
% EEG_save_path: The location you want these files to be pasted to
%
% Description: Since it gets problematic to manipulate files on the server,
% it might be ideal to copy raw files over locally

function copy_paste_EEG_files(EEG_Type, EEG_Pathway, EEG_save_path)

    % === Part 1: Load in all file names from the EEG_Pathway
    EEG_files = {};
    % Load in the files 
    for i = 1:length(EEG_Type)
        EEG_files{i} = load_EEG_names(EEG_Pathway, EEG_Type{i}, 'no');
    end

    % Stack all file names on top of each other
    all_EEG_files = horzcat(EEG_files{:})';

    % === Part 2: Load in all file names from the EEG_save_pathway
    saved_EEG_files = {};

    % Load in the files 
    for i = 1:length(EEG_Type)
        saved_EEG_files{i} = load_EEG_names(EEG_save_path, EEG_Type{i}, 'no');
    end

    % Stack all file names on top of each other
    all_saved_EEG_files = horzcat(saved_EEG_files{:})';

    % === Part 3: Remove files that have already been preprocessed
    new_EEG_files = all_EEG_files(~contains(all_EEG_files, all_saved_EEG_files));

    % === Part 4: Copy only the new files to the EEG_save_path === %
    if isempty(new_EEG_files)
        fprintf('No new files to copy.\n');
        return;
    end

    % Initialize progress bar
    h = waitbar(0, 'Copying new EEG files...');

    for i = 1:length(new_EEG_files)
        % Define source and destination paths
        srcFile = fullfile(EEG_Pathway, new_EEG_files{i});
        destFile = fullfile(EEG_save_path, new_EEG_files{i});

        % Check if file exists before copying
        if exist(srcFile, 'file')
            copyfile(srcFile, destFile);
            fprintf('Copied: %s\n', new_EEG_files{i});
        else
            fprintf('File not found: %s\n', new_EEG_files{i});
        end

        % Update waitbar
        waitbar(i / length(new_EEG_files), h, sprintf('Copying %d of %d', i, length(new_EEG_files)));

        % Optional: Add a small delay if copying too many files at once
        pause(0.2);
    end

    % Close waitbar
    close(h);

    fprintf('All new files copied successfully!\n');
end
