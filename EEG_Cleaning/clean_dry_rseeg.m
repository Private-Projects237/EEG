% INPUT: 
% EEG_fullpath: EEG pathway and file names together (ex: 'C:/user/EEG/001_GnG.eeg')
% EEG_file_type: EEG file extension ('.set'/'.vhdr')
% create_ouput_dir: Creates folder names if they don't exit ('Yes'/'No')
% chan_loc: channel location pathway
% electrode_num : number of electrodes in the recording (62, 32)
% Band-pass filter: provide a range within brackets (ex: [1 30])
% srate_ds : sampling rate to downsample to
% noiseThreshold_uV: EEG segment rejection threshold (70, 100)
% input_ex: Part of the EEG name and extension (ex: '_RAW.set')
% output_ex: Part of the EEG name and extension after cleaning (ex: '_cleaned_RAW.set')
% EEG_save_path: Pathway to save cleaned EEG files
% EEG_csv_save_path: Pathway to save EEG cleaning QS report
% EEG_excel_save_path: Pathway to create the FINAL EEG cleaning QS report

function output = clean_dry_rseeg(eegFiles, EEG_Pathway)

   % Preallocate a cell array for storing results
    numFiles = length(eegFiles);
    resultsArray = cell(1, numFiles);

    % Parallel loop for processing EEG files
    parfor i = 1:numFiles
        % Initialize a struct for results storage
        result = struct();
        
        try
            % Load EEG file
            EEG = pop_loadbv(EEG_Pathway, eegFiles{i});
            result.FileName = eegFiles{i}; % Log file name
            
            % Band-pass filter
            EEG = pop_eegfiltnew(EEG, 'locutoff',1, 'hicutoff',30);
            result.BandPassFilt = '1-30 Hz';

            % Obtain channel number
            chanNum = EEG.nbchan; 
            result.StartingChan = chanNum;

            % Identify bad channels (correlation-based)
            [~, badChannelsIdx] = clean_channels(EEG, .4, 4, 5);

            if sum(badChannelsIdx) > 0
                badChannelLabels = {EEG.chanlocs(badChannelsIdx).labels};
                badChannelsNum = find(badChannelsIdx);
            else
                badChannelLabels = {};
                badChannelsNum = [];
            end
            result.BadChannels_Poor_Corr = badChannelLabels;
            result.NumBadChannels_Poor_Corr = length(badChannelLabels);

            % Identify bad channels (variance-based)
            [badChannelLabels2, badChannelsNum2] = detect_noisy_channels_segmented(EEG, 5, 10);
            result.BadChannels_SD_Seg = badChannelLabels2;
            result.NumBadChannels_SD_Seg = length(badChannelLabels2);

            % Combine all bad channels
            allBadChannelLabels = unique([badChannelLabels, badChannelLabels2]);
            allbadChannelsNum = unique([badChannelsNum; badChannelsNum2]);
            result.AllBadChannels = allBadChannelLabels;
            result.NumAllBadChannels = length(allBadChannelLabels);

            % Interpolate bad channels
            if ~isempty(allbadChannelsNum)
                EEG = pop_interp(EEG, allbadChannelsNum, 'spherical');
                result.InterpolationDone = true;
            else
                result.InterpolationDone = false;
            end

            % Save recording length before ASR
            result.RecordingLength_BeforeASR = size(EEG.data, 2) / EEG.srate;

            % Apply ASR
            EEG = clean_asr(EEG, 6, 0.5, [], 0.7, 0.15, [-3.5, 5.5], 1, false, false, []);

            % Save recording length after ASR
            result.RecordingLength_AfterASR = size(EEG.data, 2) / EEG.srate;

            % Re-reference to mastoid electrodes
            refelec = [10 20];
            EEG = pop_reref(EEG, refelec);
            result.RereferencedTo = strjoin(arrayfun(@num2str, refelec, 'UniformOutput', false), ', ');

            % Downsample
            EEG = pop_resample(EEG, 500);
            result.DownsampledTo = 500;

            % Compute PCA dimension
            PCA_num = chanNum - length(allbadChannelsNum) - length(refelec);
            result.PCA_Dimension = PCA_num;

            % Run ICA
            EEG = pop_runica(EEG, 'extended', 1, 'pca', PCA_num, 'lrate', 5e-5, 'maxsteps', 2000, 'stop', 1e-7, 'verbose', 'off');
            result.ICA_Done = true;

            % Run IC Label
            EEG = iclabel(EEG);
            result.ICLabel_Done = true;

            % Save IC classification
            ic_scores = EEG.etc.ic_classification.ICLabel.classifications;

            % Identify artifact components
            eye_comp = find(ic_scores(:, 2) > 0.8);
            muscle_comp = find(ic_scores(:, 3) > 0.8);
            heart_comp = find(ic_scores(:, 4) > 0.8);
            line_comp = find(ic_scores(:, 5) > 0.8);
            chan_comp = find(ic_scores(:, 6) > 0.8);

            result.EyeComponents = length(eye_comp);
            result.MuscleComponents = length(muscle_comp);
            result.HeartComponents = length(heart_comp);
            result.LineComponents = length(line_comp);
            result.ChannelComponents = length(chan_comp);

            % Combine all components for rejection
            components_to_reject = unique([eye_comp; muscle_comp; heart_comp; line_comp; chan_comp]);
            result.ComponentsRemoved = length(components_to_reject);

            % Remove components
            if ~isempty(components_to_reject)
                EEG = pop_subcomp(EEG, components_to_reject, 0);
                result.ComponentsRemovalDone = true;
            else
                result.ComponentsRemovalDone = false;
            end

            % Store result in cell array for parallel compatibility
            resultsArray{i} = result;
            
        catch ME
            % If an error occurs, store it in the results structure
            warning('Error processing file %s: %s', eegFiles{i}, ME.message);
            result.ErrorMessage = ME.message;
            resultsArray{i} = result;
        end
    end

    % Convert results to a table after `parfor`
    resultsTable = struct2table(cell2mat(resultsArray), 'AsArray', true);

end

