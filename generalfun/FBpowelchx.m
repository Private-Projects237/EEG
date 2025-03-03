% INPUT
% bands: names of frequency bands (character vector)
% frexvc: frequency band ranges (numeric matrix)
% inputdir: the pathway to where the EEG files are (character vector)
% filenames: EEG files that need to read (character vector)
% winsec: time window length in seconds
% nOverlap_per: time window percent overlap
% outputdir: The pathway to where the structures are saved  (character scalar)
% outputname: The extension name for saved strucrt files (character)
%
% OUPUT (Structure; .mat file):
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
% Description: '.set' files will be loaded and then and then 
% fftx2 will be used on each one. The average power output
% from fftx2 will be indexed into frequency bands and then
% averaged to get one power value per each frequency bands for
% all channels. This information will be saved as a structure
% array and be saved as a .mat file for all EEG files. 
%
% Example:
% FBpowfftx(bands, frexvc, filenames, inputdir, outputdir)

function FBpowelchx(bands, frexvc, inputdir, filenames, winsec, nOverlap_per, outputdir, outputname)


    % Identify files that have a struct completed (already processed)
    structfiles = dir(fullfile(outputdir, append('*', outputname)));  
    structsprocessed = {structfiles.name}; 
    
    % Remove filenames from loop iteration if they have a struct saved
    filesprocessed = strrep(structsprocessed, outputname, ".set");
    filenames = filenames(~ismember(filenames, filesprocessed));

    % Create a structure called awelchx because MATLAB is being dumb
    awelchx = struct('filename', {}, 'hz', {}, 'powavg', {}, 'chanlabl', {}, ...
                 'deltaFB', {}, 'thetaFB', {}, 'alphaFB', {}, 'betaFB', {}, ...
                 'avgdelta', {}, 'avgtheta', {}, 'avgalpha', {}, 'avgbeta', {});

    % Function to process FFT data from multiple files and save the results 
    parfor welci = 1:length(filenames)
        try
            % Construct the full path to the file
            currentFile = fullfile(inputdir, filenames{welci});
            EEG = pop_loadset('filename', filenames{welci}, 'filepath', inputdir);

            % Run welchx2
            current_welchx = welchx2(EEG.data, EEG.srate, winsec, nOverlap_per, filenames{welci});
    
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
    
            % Compute mean for each frequency band
            for bandIdx = 1:size(frexvc, 1)
                bandName = bands{bandIdx};
                tempStruct.(sprintf('avg%s', bandName)) = mean(tempStruct.(sprintf('%sFB', bandName)),2);
            end

            % Save the temporary struct into another struct for later
            % saving
            awelchx(welci) = tempStruct;
            
    
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
            savefilename = fullfile(outputdir, strrep(current_awelchx.filename, ".set", outputname));
            % save the struct individually
            save(savefilename, 'current_awelchx');
        end

    end

end

