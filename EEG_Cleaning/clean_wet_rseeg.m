% INPUT: 
% EEG_fullpath: EEG pathway and file names together (ex: 'C:/user/EEG/001_GnG.eeg')
% EEG_file_type: EEG file extension ('.set'/'.eeg')
% EEG_save_path: Pathway to save cleaned EEG files
% EEG_csv_save_path: Pathway to save EEG cleaning QS report
% EEG_excel_save_path: Pathway to create the FINAL EEG cleaning QS report
% create_ouput_dir: Creates folder names if they don't exit ('Yes'/'No')
% chan_loc: channel location pathway
% electrode_num : number of electrodes in the recording (62, 32)
% srate_ds : sampling rate to downsample to
% noiseThreshold_uV: EEG segment rejection threshold (70, 100)
% input_ex: Part of the EEG name and extension (ex: '_RAW.set')
% output_ex: Part of the EEG name and extension after cleaning (ex: '_cleaned_RAW.set')
%
% OUTPUT
% Cleaned EEG data as .set and .fdt files
% Indivdual EEG Cleaning QS reports
% A Main Excel File with all EEG Cleaning QS Reports
%
% Description: This function was made to clean wet resting-state EEG data.
% Do not use for any other type of EEG data like ERPs nor dry-EEG. This
% function uses PARALLEL PROCESSING- make sure you have a fast computer
% to handle this. Additional TOOLBOXES are need to get this script to work.
% ICLabel was chosen for artifact component rejection instead of MARA. Do
% copy files locally instead of workion on the server for increased
% computational speed. 

function output = clean_wet_rseeg(EEG_fullpath, EEG_file_type, EEG_save_path, EEG_csv_save_path, EEG_excel_save_path, create_ouput_dir, chan_loc, electrode_num, srate_ds, noiseThreshold_uV, input_ex, output_ex)
    
    % Define pathways
    EEG_save_path = fullfile(EEG_save_path);
    EEG_csv_save_path = fullfile(EEG_csv_save_path);

    % Separate EEG file names from their pathway
    EEG_files = cellfun(@(x) x(max(strfind(x, '\')) + 1:end), EEG_fullpath, 'UniformOutput', false);
    
    % Extract everything except the last part of each path
    EEG_pathway_all = cellfun(@(x) fileparts(x), EEG_fullpath, 'UniformOutput', false);
    EEG_pathway = char(append(EEG_pathway_all(1),'\'));

    % Remove already processed files
    processed_EEG_files = {dir(EEG_save_path).name};
    eegFiles = EEG_files(~ismember(EEG_files, strrep(EEG_files,input_ex,output_ex)));

    % Initialize variables
    N = length(eegFiles);
    results = struct('FileDate', cell(1,N), 'InitialSec', zeros(1,N), 'StartingChannels', zeros(1,N), ...
                     'rank1', zeros(1,N), 'Num_Interpolation', zeros(1,N), 'BadChannelsString', cell(1,N),...
                     'reReferenceType', cell(1,N) , 'rank2', zeros(1,N), 'PCA_number', zeros(1,N), ...
                     'RejectedComponentNumber', zeros(1,N), 'CompRejsString', cell(1,N), ...
                     'RemainingSec', zeros(1,N), 'Percent_Remaining', zeros(1,N), 'Error', cell(1,N));

    % Run the for loop
    parfor ii = 1:N
        try

            % Identify which EEG file type to load
            if strcmp(EEG_file_type, ".set")
                % load .set files
                Current_eegFile = eegFiles{ii}
                EEG = pop_loadset('filename', Current_eegFile, ...
                    'filepath', EEG_pathway);

            elseif strcmp(EEG_file_type, ".eeg")
                % load BVA files (CURRENTLY NOT WORKING)
                Current_eegFile = eegFiles{ii};
                Current_vhdrFile = strrep(Current_eegFile, '.eeg', '.vhdr');
                EEG = pop_loadbv(current_conditionPathway, Current_vhdrFile);

            end

            % Obtain the date of the EEG recording
            fileInfo = dir(fullfile(EEG_pathway, Current_eegFile));
            results(ii).FileDate = fileInfo.date;

            %Removing not needed channels
            EEG = pop_select( EEG, 'nochannel',{'Aux1','Aux2','VEOG','HEOG'})

            % Obtain some parameters about the recording before cleaning
            results(ii).InitialSec = size(EEG.data, 2) / EEG.srate;
            results(ii).StartingChannels = EEG.nbchan;
            results(ii).rank1 = rank(EEG.data);

            % Adding channels
            EEG=pop_chanedit(EEG, 'lookup', chan_loc)

            % Filter the data (1-30 Hz)
            EEG = pop_eegfiltnew(EEG, 'locutoff',1,'hicutoff',30);

            % Identify problematic electrodes
            EEG1 = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,'WindowCriterion','off','BurstRejection','on','Distance','Euclidian');
            if isfield(EEG1.etc, 'clean_channel_mask')
                Bad_Channels = find(~EEG1.etc.clean_channel_mask);
                results(ii).Num_Interpolation = length(Bad_Channels);
                EEG = pop_interp(EEG, Bad_Channels, 'spherical');
            else
                results(ii).Num_Interpolation = 0;
                Bad_Channels = {0};
            end
            results(ii).BadChannelsString = sprintf('%g, ', Bad_Channels{1});
            results(ii).BadChannelsString(end-1:end) = []; % Remove the trailing comma and space
            
            % Rereference based on channel numbers
            if electrode_num > 60
                % Re-reference to full head
                EEG = pop_reref( EEG, []);
                results(ii).reReferenceType = "WholeHead"
            else
                % Re-reference to mastoid electrodes
                EEG = pop_reref(EEG, [10 21]);
                results(ii).reReferenceType = "TP9, TP10"
            end

            % Down sample if necessary (helps speed up ICA at the cost of
            % losing data)
            EEG = pop_resample(EEG, srate_ds);

            % Calculate the PCA number (Indicator of Rank essentially)
            if electrode_num > 60
                % Subtract by 1 for whole head re-referencing
                results(ii).PCA_number = results(ii).StartingChannels - results(ii).Num_Interpolation - 1;
                
            else
                % Subtract by 2 for mastoud re-referencing
                results(ii).PCA_number = results(ii).StartingChannels - results(ii).Num_Interpolation - 2;
                
            end
            
            % Run ICA using runica
            EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'pca',results(ii).PCA_number,'interrupt','on');
            
            % Identify bad components using ICLabel (We don't need the data
            % too cleaned)
            EEG = pop_iclabel(EEG, 'default');
            
            % Identify eye and muscle components
            eye_components = find(EEG.etc.ic_classification.ICLabel.classifications(:, 3) > 0.8);
            muscle_components = find(EEG.etc.ic_classification.ICLabel.classifications(:, 2) > 0.8);
            
            % Save this information in an object 
            RejectedEyeComponentNum = length(eye_components);
            RejectedMuscleComponentNum = length(muscle_components);
            
            % Combine eye and muscle component
            Rejected_Component = unique([eye_components; muscle_components]);
            
            % Remove bad components 
            EEG = pop_subcomp(EEG, Rejected_Component, 0);
 
            % Convert components_to_reject into a string variable
            results(ii).RejectedComponentNumber = length(Rejected_Component);
            results(ii).CompRejsString = sprintf('%g, ', Rejected_Component); % Create a comma-separated string
            results(ii).CompRejsString(end-1:end) = []; % Remove the trailing comma and space

            % Delete segments of data that are too noise (strict)
            EEG.data(:, any(abs(EEG.data) >= noiseThreshold_uV, 1)) = [];
            results(ii).RemainingSec = size(EEG.data, 2) / EEG.srate;
            results(ii).Percent_Remaining = round(results(ii).RemainingSec / results(ii).InitialSec * 100, 2);

            % Ranking after full cleaning
            results(ii).rank2 = rank(EEG.data);

            % Save the processed EEG file
            Save_FileName = strrep(Current_eegFile, input_ex, output_ex);
            EEG = pop_saveset(EEG, 'filename', Save_FileName, 'filepath', EEG_save_path);
        
        catch ME

            % Save the error message as an object
            results(ii).Error = ME.message;
    
            % Save results only if the value hasn't already been set
            if isempty(results(ii).FileDate)
                results(ii).FileDate = '-';
            end
            if sum(results(ii).InitialSec) == 0
                results(ii).InitialSec = 0;
            end
            if sum(results(ii).rank1) == 0
                results(ii).rank1 = 0;
            end
            if sum(results(ii).StartingChannels) == 0
                results(ii).StartingChannels = 0;
            end
            if sum(results(ii).Num_Interpolation) == 0
                results(ii).Num_Interpolation = 0;
            end
            if isempty(results(ii).BadChannelsString)
                results(ii).BadChannelsString = '-';
            end
            if isempty(results(ii).reReferenceType)
                results(ii).reReferenceType = '-';
            end
            if sum(results(ii).PCA_number) == 0
                results(ii).PCA_number = 0;
            end
            if sum(results(ii).RejectedComponentNumber) == 0
                results(ii).RejectedComponentNumber = 0;
            end
            if isempty(results(ii).CompRejsString)
                results(ii).CompRejsString = {'-'};
            end
            if sum(results(ii).RemainingSec) == 0
                results(ii).RemainingSec = 0;
            end
            if sum(results(ii).Percent_Remaining) == 0
                results(ii).Percent_Remaining = 0;
            end
            if sum(results(ii).rank2) == 0
                results(ii).rank2 = 0;
            end

        end

        
    end

    % Save results to CSV
    for ii = 1:N
        Output_Table = table( ...
            {results(ii).FileDate}, {eegFiles{ii}}, ...
            results(ii).InitialSec, results(ii).rank1, ...
            results(ii).StartingChannels, results(ii).Num_Interpolation, ...
            {results(ii).BadChannelsString}, {results(ii).reReferenceType}, results(ii).PCA_number, ...
            results(ii).RejectedComponentNumber, {results(ii).CompRejsString}, ...
            results(ii).RemainingSec, results(ii).Percent_Remaining, ...
            results(ii).rank2, {results(ii).Error}, ...
            'VariableNames', {'Date', 'File_Name', 'Start_Recording_Sec', ...
            'EEG_Rank1', 'Channel_Num', 'Interpolated_Chan_Num', ...
            'Interpolated_Channels', 'reReference_Type' ,'PCA_Number', 'Rejected_Components_Num', ...
            'Rejected_Components' ,'Remaining_Recording_Sec', 'Percent_Remaining', ...
            'EEG_Rank2', 'Error'});
        writetable(Output_Table, fullfile(EEG_csv_save_path, append(strrep(eegFiles{ii}, input_ex, output_ex),'.csv')  ));
    end


    % Combine all CSV reports
    csvFiles = dir(fullfile(EEG_csv_save_path, '*.csv'));
    combinedData = table();
    for i = 1:length(csvFiles)
        currentData = readtable(fullfile(csvFiles(i).folder, csvFiles(i).name));
        combinedData = [combinedData; currentData];
    end
    % combinedData = sortrows(combinedData, 'Date');
    CleaningEEGQC_fullpath = append(EEG_excel_save_path, 'Wet_EEG_Cleaning_Final_Report.xlsx');
    writetable(combinedData, CleaningEEGQC_fullpath);
end