% This function was created to reduce the overhead of parallel processing,
% which will use up too much memory and slow down everything. 
% INPUT: 
% eegfiles: eeg files without full pathway (ex: '001_GnG.eeg')
% EEG_Raw_Pathway: The directory to where the raw EEG files are
% EEG_Clean_Pathway: The location you want the cleaned EEG files to be saved
% EEG_CSV_Save_Pathway: The location you want the EEG QC CSV to be saved
% preprocParams : Load the 'WetrsEEFParameters' mat file
% batchSize: Number of files that will go through par for (e.g., 25)
%
% Description: This code will clean dry-EEG data and create a QC report for
% each file. 

function output = clean_wet_rseeg2(eegFiles, EEG_Raw_Pathway, EEG_Clean_Pathway, EEG_CSV_Save_Pathway, preprocParams, batchSize)
    
    % Obtain the number of files to calculate iterations needed based on batchSize
    numFiles = length(eegFiles);
    
    % Wrap preprocParams in parallel.pool.Constant for efficient memory usage
    ppConstant = parallel.pool.Constant(preprocParams);

    % Iterate in chunks of batchSize
    for startIdx = 1:batchSize:numFiles
        endIdx = min(startIdx + batchSize - 1, numFiles);
        currentBatch = eegFiles(startIdx:endIdx);

        % Parallel loop for processing EEG files
        parfor i = 1:length(currentBatch)
            
            % Access the preprocParams from the Constant
            preprocParams = ppConstant.Value;

            % Define filenames for processed EEG and QC file
            eeg_save_file = fullfile(EEG_Clean_Pathway, ...
                strrep(currentBatch{i}, preprocParams.fileExtRaw, preprocParams.fileExtEeg));
            csv_save_file = fullfile(EEG_CSV_Save_Pathway, ...
                strrep(currentBatch{i}, preprocParams.fileExtRaw, preprocParams.fileExtQc));

            % Initialize results struct
            result = clean_wet_rseeg_result_struct(currentBatch{i});

            try
                % Recording function used
                result.usedFunction = mfilename;

                % Load EEG file
                if strcmp(preprocParams.fileExtRaw, '.set')
                    EEG = pop_loadset('filename', currentBatch{i}, 'filepath',EEG_Raw_Pathway);
                     result.FileName = currentBatch{i};
                else 
                    EEG = pop_loadbv(EEG_Raw_Pathway, currentBatch{i});
                    result.FileName = currentBatch{i};
                end
                
                % Convert EEG data to double
                EEG.data = double(EEG.data);

                % === Obtain Date of the EEG File ===
                fileInfo = dir(fullfile(EEG_Raw_Pathway, currentBatch{i}));
                result.Date = {fileInfo.date};

                % === Removing unwanted channels ===
                EEG = pop_select( EEG, 'nochannel', preprocParams.chanRmv);

                % === Adding channel Locations ===
                EEG = pop_chanedit(EEG, 'lookup', preprocParams.chanLoc);

                % === Rank Before Processing ===
                result.Rank_BeforeCleaning = rank(double(reshape(EEG.data, EEG.nbchan, [])));

                % === Number of Channels & Obtain Amplitude Average 1 ===
                result.StartingChan = EEG.nbchan;
                result.avgAmpRange1 = get_eeg_seg_amp_range(EEG, 5);

                % === Remove DC Offset & Obtain Amplitude Average 2 ===
                if strcmp(preprocParams.detrend, 'yes') 
                    EEG.data = detrend(EEG.data); % https://sccn.ucsd.edu/pipermail/eeglablist/2011/003135.html
                    result.removedDCOffset = 'true';
                end
                result.avgAmpRange2 = get_eeg_seg_amp_range(EEG, 5);

                % === Band-pass Filtering & Obtain Amplitude Average 3 ===
                EEG = pop_eegfiltnew(EEG, 'locutoff', preprocParams.filtLow, 'hicutoff', preprocParams.filtHigh);
                result.BandPassFilt = sprintf('%d-%d Hz', preprocParams.filtLow, preprocParams.filtHigh);
                result.avgAmpRange3 = get_eeg_seg_amp_range(EEG, 5);

                % === Remove Line Noise (it works but kinda sucks)===
                EEG = pop_eegfiltnew(EEG, ...
                                     preprocParams.NotchfiltLow, ...
                                     preprocParams.NotchfiltHigh, ...
                                     [], 1, [], 0);

                % === Bad Channel Detection (Conventional) ===
                 EEG1 = pop_clean_rawdata(EEG, ...
                'FlatlineCriterion', preprocParams.badChFlatLineCrit, ...
                'ChannelCriterion', preprocParams.badChChannCrit, ...
                'LineNoiseCriterion', preprocParams.badChLineNoise); % 

                 % Identify problematic electrodes
                if isfield(EEG1.etc, 'clean_channel_mask')
                    badChannelsIdx = find(~EEG1.etc.clean_channel_mask);
                    result.NumAllBadChannels = length(badChannelsIdx);
                    badChannelLabels = {EEG.chanlocs(badChannelsIdx).labels};
                    result.AllBadChannels = {strjoin(badChannelLabels(:), ', ')};

                else
                    result.AllBadChannels = {"-"};
                    result.NumAllBadChannels = 0;
                end

                % === Interpolation of Bad Channels & Obtain Amplitude Average 4 ===
                EEG1 = [];
                if result.NumAllBadChannels ~= 0
                    EEG = pop_interp(EEG, badChannelsIdx, 'spherical');
                    result.InterpolationDone = 'true';
                end 
                result.avgAmpRange4 = get_eeg_seg_amp_range(EEG, 5);

                % === Re-referencing & Obtain Amplitude Average 5 ===
                reRefLabels = {EEG.chanlocs(preprocParams.reRefchan).labels};
                EEG = pop_reref(EEG, preprocParams.reRefchan);
                result.RereferencedTo = strjoin(reRefLabels(:), ', ');
                if isempty(preprocParams.reRefchan)
                    result.RereferencedTo = 'WholeHead';
                    reRefLabels = 1;
                end
                result.avgAmpRange5 = get_eeg_seg_amp_range(EEG, 5);

                % === Downsampling ===
                EEG = pop_resample(EEG, preprocParams.downrate);
                result.DownsampledTo = preprocParams.downrate;

                % === ICA ===
                PCA_Dimension = result.StartingChan - result.NumAllBadChannels - length(reRefLabels);
                result.PCA_Dimension = PCA_Dimension;
                EEG = pop_runica(EEG, 'extended', preprocParams.ICAext, 'pca', PCA_Dimension, ...
                                 'lrate', preprocParams.ICAlrate, 'maxsteps', preprocParams.ICAsteps, ...
                                 'stop', preprocParams.ICAstopTol, 'verbose', 'off');
                result.ICA_Done = 'true';

                % === Save ICA dataset ===
                pop_saveset(EEG, 'filename', strrep(eeg_save_file,'.set','_ICA.set'));
                result.ICA_Saved = 'true';
                
                % === IC Label: Find and Report Artifact Components ===
                EEG = iclabel(EEG);
                ic_scores = EEG.etc.ic_classification.ICLabel.classifications;
                [result, components_to_reject]= find_artifact_components(ic_scores, 20, preprocParams, result);
                result.ICLabel_Done = 'true';

                % === Remove Artifact Components & Obtain Amplitude Average 6 ===
                if ~isempty(components_to_reject)
                    EEG = pop_subcomp(EEG, components_to_reject, 0);
                    result.ComponentsRemoved = length(components_to_reject);
                else 
                    result.ComponentsRemoved = 0;
                end
                result.ComponentsRemovalDone = 'true';
                result.avgAmpRange6 = get_eeg_seg_amp_range(EEG, 5);
                
                % Safe cleanup of ICA variables
                ic_scores = [];

                % === Rank After Processing ===
                result.Rank_AfterCleaning = rank(double(reshape(EEG.data, EEG.nbchan, [])));

                % === Save the Length of the Recording ===
                result.EEGLengthSec = round(size(EEG.data,2)/EEG.srate,2);

                % === Segmentation Rejection Num (NOt ACTUALLY REJECTING) ===
                [segmentsQC] = seg_reject_num(EEG, preprocParams.badSegthresh, ...
                                                   preprocParams.badSegsec, ...
                                                   preprocParams.badSegOverlp);

                % === Save Segmentation Rejection Output
                result.SegTotalNum = segmentsQC.n_segments;
                result.SegOverlapPercent = segmentsQC.overlapPercent;
                result.SegTotalNumOverlap = segmentsQC.n_segmentsOverlap;
                result.SegGoodNum = segmentsQC.n_goodsegments;
                result.SegBadNum = segmentsQC.n_badsegments;
                result.SegPropGood = segmentsQC.propRemaining;

                % === Save Processed EEG File ===
                pop_saveset(EEG, 'filename', eeg_save_file);
                EEG = [];

                % === Save QC Report ===
                result.savedFile = regexp(csv_save_file, '[^/\\]+$', 'match', 'once');
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
        
        % Restart parallel pool after each batch to clear memory
        delete(gcp('nocreate'));
        parpool;
        
    end

end