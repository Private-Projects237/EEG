% INPUT
% bands: names of frequency bands (character vector)
% frexvc: frequency band ranges (numeric matrix)
% EEG_Clean_Pathway: the pathway to where the EEG files are (character vector)
% filenames: EEG files that need to read (character vector)
% winsec: time window length in seconds
% nOverlap_per: time window percent overlap
% EEG_Welch_Pathway: The pathway to where the structures are saved  (character scalar)
% EEG_Plot_Pathway: The pathway to where the data to generate plots is saved (channel, hz, power matrix)
% outputname: The extension name for saved strucrt files (character)
% preprocParams: The struct that has the parameters for preprocessing
%
% OUTPUT (Structure; .mat file):
% filename: the name of the original EEG file
% hz: frequency vector
% powavg: avg power corresponding to frequency vector
% chanlabl: the names of the channels
% deltaFB: Index of time points associated with delta
% thetaFB: Index of time points associated with theta
% alphaFB: Index of time points associated with alpha
% betaFB: Index of time points associated with beta
% avgdelta: the average power within the deltaFB time points
% avgtheta: the average power within the deltaFB time points
% avgalpha: the average power within the deltaFB time points
% avgbeta: the average power within the deltaFB time points
%
% OUTPUT (.txt file)
% A data frame with information about the power for each channel across
% the high possible Hz that is sensible. This information is good for
% plotting the power spectrums for rsEEG.
%
% Description: '.set' files will be loaded and then and then 
% welchx2 will be used on each one. The average power output
% from welchx2 will be indexed into frequency bands and then
% averaged to get one power value per each frequency bands for
% all channels. This information will be saved as a structure
% array and be saved as a .mat file for all EEG files. 
%

function extract_eeg_freqband_power_welchx(bands, frexvc, EEG_Clean_Pathway, filenames, winsec, nOverlap_per, EEG_Welch_Pathway, EEG_Plot_Pathway, outputname, preprocParams)


    % Identify files that have a struct completed (already processed)
    structfiles = dir(fullfile(EEG_Welch_Pathway, append('*', outputname)));  
    structsprocessed = {structfiles.name}; 
    
    % Remove filenames from loop iteration if they have a struct saved
    filesprocessed = strrep(structsprocessed, outputname, ".set");
    filenames = filenames(~ismember(filenames, filesprocessed));

    % Function to process FFT data from multiple files and save the results 
    parfor welci = 1:length(filenames)
        try
            % Construct the full path to the file
            currentFile = fullfile(EEG_Clean_Pathway, filenames{welci});
            EEG = pop_loadset('filename', filenames{welci}, 'filepath', EEG_Clean_Pathway);

            % Run welchx3
            current_welchx = welchx3(EEG.data, EEG.srate, winsec, nOverlap_per, filenames{welci}, preprocParams.badSegthresh);
    
            % Temporary struct to store data
            tempStruct = struct();
            tempStruct.filename = current_welchx.filename;
            tempStruct.hz = current_welchx.hz;
            tempStruct.powavg = current_welchx.powavg;
            tempStruct.chanlabl = {EEG.chanlocs.labels}';
    
            % Find indices for frequency bands
            fzi = zeros(size(frexvc, 1), 2);
            for bandIdx = 1:size(frexvc, 1)
                fzi(bandIdx, :) = dsearchn(tempStruct.hz', frexvc(bandIdx, :)');
            end
    
            % Save the raw values for each frequency band for each channel
            for bandIdx = 1:size(frexvc, 1)
                bandName = bands{bandIdx};
                tempStruct.(sprintf('%sFB', bandName)) = tempStruct.powavg(:,fzi(bandIdx, 1):fzi(bandIdx, 2));
            end
    
            % Compute the sum for each frequency band (Absolute Power)
            for bandIdx = 1:size(frexvc, 1)
                bandName = bands{bandIdx};
                tempStruct.(sprintf('abs%s', bandName)) = sum(tempStruct.(sprintf('%sFB', bandName)),2);
            end
    
            % Compute mean for each frequency band (Averaged Power Within FB)
            for bandIdx = 1:size(frexvc, 1)
                bandName = bands{bandIdx};
                tempStruct.(sprintf('avg%s', bandName)) = mean(tempStruct.(sprintf('%sFB', bandName)),2);
            end

            % Compute total power across all frequency bands
            totalPower = zeros(size(tempStruct.powavg, 1), 1); % Initialize total power vector
            for bandIdx = 1:size(frexvc, 1)
                bandName = bands{bandIdx};
                totalPower = totalPower + sum(tempStruct.(sprintf('%sFB', bandName)), 2); % Sum power across all bands
            end
            
            % Compute relative power for each frequency band
            for bandIdx = 1:size(frexvc, 1)
                bandName = bands{bandIdx};
                % Calculate relative power by dividing the absolute power of the band by the total power
                tempStruct.(sprintf('rel%s', bandName)) = tempStruct.(sprintf('abs%s', bandName)) ./ totalPower;
            end

            % Save the temporary struct into another struct for later
            % saving
            awelchx(welci) = tempStruct;

            % Create a matrix that will be used for plotting later
            dataset = cell(1 + length(tempStruct.chanlabl),...
                           1 + length(tempStruct.hz));
            dataset(1,1) = {'Channel'};
            dataset(1,2:end) = num2cell(tempStruct.hz);
            
            % Set first column: channel labels
            dataset(2:end,1) = tempStruct.chanlabl;
            dataset(2:end,2:end) = num2cell(tempStruct.powavg);

            % Save the dataset
            writetable(cell2table(dataset), append(EEG_Plot_Pathway, strrep(tempStruct.filename, '.set', '_ch_hz_pow.txt')),...
                       'Delimiter', '\t', 'WriteVariableNames', false);

        catch ME
            fprintf('Error processing file %s: %s\n', filenames{welci}, ME.message);
        
        end
    
    end

    % only save files if there were any files processed
    if length(filenames) ~= 0
        
        % Save the information using a for loop instead of parfor
        for awelchxi = 1:length(awelchx)
            % Index the full struct -_-
            current_awelchx = awelchx(awelchxi);
            % create the save file na,e
            savefilename = fullfile(EEG_Welch_Pathway, strrep(current_awelchx.filename, ".set", outputname));
            % save the struct individually
            save(savefilename, 'current_awelchx');
        end

    end

end

