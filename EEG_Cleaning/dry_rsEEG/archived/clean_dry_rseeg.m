% INPUT: 
% eegfiles: eeg files without full pathway (ex: '001_GnG.eeg')
% EEG_Pathway: The directory to where the raw EEG files are
% EEG_save_path: The location you want the cleaned EEG files to be saved
% EEG_csv_save_path: The location you want the EEG QC CSV to be saved
% preprocParams : Load the 'DryEEGParameters' mat file
% batchSize: Number of files that will go through par for (e.g., 25)
%
% Description: This code will clean dry-EEG data and create a QC report for
% each file. 

function clean_dry_rseeg(eegFiles, EEG_Pathway, EEG_save_path, EEG_csv_save_path, preprocParams, batchSize)

    % Obtain the number of files to calculate iterations needed based on batchSize
    numFiles = length(eegFiles);

    % Iterate in chunks of batchSize
    for startIdx = 1:batchSize:numFiles
        endIdx = min(startIdx + batchSize - 1, numFiles);
        currentBatch = eegFiles(startIdx:endIdx);

        % Parallel loop for processing EEG files
        parfor i = 1:length(currentBatch)

            % Define filenames for processed EEG and QC file
            eeg_save_file = fullfile(EEG_save_path, strrep(currentBatch{i}, '.vhdr', preprocParams.fileExt.eeg));
            csv_save_file = fullfile(EEG_csv_save_path, strrep(currentBatch{i}, '.vhdr', preprocParams.fileExt.qc));

            % Initialize results struct
            result = clean_dry_rseeg_result_struct(currentBatch{i});

            try
                % Recording function used
                result.usedFunction = mfilename;

                % Load EEG file
                EEG = pop_loadbv(EEG_Pathway, currentBatch{i});
                result.FileName = currentBatch{i};

                % Convert EEG data to double
                EEG.data = double(EEG.data);

                % === Obtain Date of the EEG File
                fileInfo = dir(fullfile(EEG_Pathway, currentBatch{i}));
                result.Date = {fileInfo.date};

                % === Rank Before Processing ===
                result.Rank_BeforeCleaning = rank(double(reshape(EEG.data, EEG.nbchan, [])));

                % === Number of Channels
                result.StartingChan = EEG.nbchan;

                % === Band-pass Filtering ===
                EEG = pop_eegfiltnew(EEG, 'locutoff', preprocParams.filt.low, 'hicutoff', preprocParams.filt.high);
                result.BandPassFilt = sprintf('%d-%d Hz', preprocParams.filt.low, preprocParams.filt.high);

                % === Obtain Avg Amplitude Range ===
                result.avgAmpRange1 = get_eeg_seg_amp_range(EEG, 5);

                % === Bad Channel Detection (Correlation) ===
                [~, badChannelsIdx] = clean_channels(EEG, ...
                    preprocParams.badCh.corrThresh, ...
                    preprocParams.badCh.LineNoiThresh, ...
                    preprocParams.badCh.WinLen);
                
                % Ensure valid indexing before extracting labels
                if sum(badChannelsIdx) > 0
                    badChannelLabels = {EEG.chanlocs(badChannelsIdx).labels}';
                    badChannelsNum = find(badChannelsIdx);
                    result.BadChannels_Poor_Corr = {strjoin(badChannelLabels(:), ', ')};
                    result.NumBadChannels_Poor_Corr = length(badChannelLabels);
                else
                    badChannelsNum = 0;
                    badChannelLabels = {};
                    result.NumBadChannels_Poor_Corr = 0;
                end
                
                % === Bad Channel Detection (Variance-Based) ===
                [badChannelLabels2, badChannelsNum2] = detect_noisy_channels_segmented(EEG, ...
                    preprocParams.badCh.varWinLen, preprocParams.badCh.varSDThresh);
                
                if ~isempty(badChannelsNum2)
                    result.BadChannels_SD_Seg = strjoin(badChannelLabels2(:), ', ');
                    result.NumBadChannels_SD_Seg = length(badChannelLabels2);
                else
                    result.NumBadChannels_SD_Seg = 0;
                end 

                % === Combining All Bad Channels ===
                allBadChannelLabels = unique([badChannelLabels; badChannelLabels2']);
                allbadChannelsNum = unique([badChannelsNum; badChannelsNum2]);

                if sum(allbadChannelsNum) > 0 
                    result.AllBadChannels = {strjoin(allBadChannelLabels(:), ', ')};
                    result.NumAllBadChannels = length(allbadChannelsNum);
                else
                    result.AllBadChannels = {"-"};
                    result.NumAllBadChannels = 0;
                end 

                % === Interpolation of Bad Channels ===
                if allbadChannelsNum ~= 0
                    EEG = pop_interp(EEG, allbadChannelsNum, 'spherical');
                    result.InterpolationDone = 'true';
                end 

                % === Recording Length Before ASR ===
                samples_before = size(EEG.data, 2);
                result.RecordingLength_BeforeASR = samples_before / EEG.srate;
                EEG_original = EEG;

                % === Apply ASR ===
                EEG = clean_asr(EEG, ...
                                preprocParams.ASR.cutoff, ...
                                preprocParams.ASR.winLen, ...
                                preprocParams.ASR.stpSz,...
                                preprocParams.ASR.maxDim, ...
                                preprocParams.ASR.ref_maxBadChn,...
                                preprocParams.ASR.ref_tol,...
                                preprocParams.ASR.ref_wndlen,...
                                false, false, []);

                % === Calculate the proportion of data that was
                % interpolated through ASR
                EEG_cleaned_asr = EEG; 
                diff_matrix = abs(EEG_original.data - EEG_cleaned_asr.data);
                result.asrDiffThreshold = 0.02 * result.avgAmpRange1;
                num_altered_points = sum(diff_matrix(:) > result.asrDiffThreshold);
                total_points = numel(EEG_original.data);
                result.Proportion_Altered = round(num_altered_points/total_points,2);

                % === Apply ASR for Bursts ===
                EEG = pop_clean_rawdata(EEG, ...
                                        'FlatlineCriterion','off', ...
                                        'ChannelCriterion','off', ...
                                        'LineNoiseCriterion','off','Highpass','off', ...
                                        'BurstCriterion',preprocParams.ASR.burstCrit,'WindowCriterion','off', ...
                                        'BurstRejection','on','Distance','Euclidian');

                % === Recording Length After ASR ===
                samples_after = size(EEG.data, 2);
                result.RecordingLength_AfterASR = samples_after / EEG.srate;
                result.ASR_Proportion_Retained = round(samples_after / samples_before, 3);

                % === Re-referencing ===
                reRefLabels = {EEG.chanlocs(preprocParams.reRef.chan).labels}; % must come before re-referencing
                EEG = pop_reref(EEG, preprocParams.reRef.chan);
                result.RereferencedTo =strjoin(reRefLabels(:), ', ');

                % === Downsampling ===
                EEG = pop_resample(EEG, preprocParams.down.rate);
                result.DownsampledTo = preprocParams.down.rate;

                % === ICA ===
                PCA_Dimension = result.StartingChan - result.NumAllBadChannels - length(reRefLabels);
                result.PCA_Dimension = PCA_Dimension;
                EEG = pop_runica(EEG, 'extended', preprocParams.ICA.ext, 'pca', PCA_Dimension, ...
                                 'lrate', preprocParams.ICA.lrate, 'maxsteps', preprocParams.ICA.steps, ...
                                 'stop', preprocParams.ICA.stopTol, 'verbose', 'off');
                result.ICA_Done = 'true';
                
                % === IC Label ===
                EEG = iclabel(EEG);
                result.ICLabel_Done = 'true';

                % Classify Components
                ic_scores = EEG.etc.ic_classification.ICLabel.classifications;
                result.EyeComponents = sum(ic_scores(:, 2) > preprocParams.ICL.thresh.eye);
                result.MuscleComponents = sum(ic_scores(:, 3) > preprocParams.ICL.thresh.muscle);
                result.HeartComponents = sum(ic_scores(:, 4) > preprocParams.ICL.thresh.heart);
                result.LineComponents = sum(ic_scores(:, 5) > preprocParams.ICL.thresh.line);
                result.ChannelComponents = sum(ic_scores(:, 6) > preprocParams.ICL.thresh.chan);

                % === Remove Components ===
                components_to_reject = find(ic_scores(:, 2) > preprocParams.ICL.thresh.eye | ...
                                            ic_scores(:, 3) > preprocParams.ICL.thresh.muscle | ...
                                            ic_scores(:, 4) > preprocParams.ICL.thresh.heart | ...
                                            ic_scores(:, 5) > preprocParams.ICL.thresh.line | ...
                                            ic_scores(:, 6) > preprocParams.ICL.thresh.chan);
                EEG = pop_subcomp(EEG, components_to_reject, 0);
                result.ComponentsRemoved = length(components_to_reject);
                result.ComponentsRemovalDone = 'true';

                % === Rank After Processing ===
                result.Rank_AfterCleaning = rank(double(reshape(EEG.data, EEG.nbchan, [])));

                % === Obtain Avg Amplitude Range ===
                result.avgAmpRange2 = get_eeg_seg_amp_range(EEG, 5);

                % === Save Processed EEG File ===
                pop_saveset(EEG, 'filename', eeg_save_file);

                % === Save QC Report ===
                resultTable = struct2table(result, 'AsArray', true);
                writetable(resultTable, csv_save_file);

            catch ME
                warning('Error processing file %s: %s', currentBatch{i}, ME.message);
                result.ErrorMessage = ME.message;
            
                % Save Partial QC Report
                resultTable = struct2table(result, 'AsArray', true);
                writetable(resultTable, csv_save_file);
            end
        end
    end
end

