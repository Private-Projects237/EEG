% INPUT
% bands: names of frequency bands (character vector)
% frexvc: frequency band ranges (numeric matrix)
% filenames: EEG files that need to read (character vector)
% inputdir: the pathway to where the EEG files are (character vector)
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

function FBpowfftx(bands, frexvc, filenames, inputdir, outputdir, outputname)

    % Identify files that have a struct completed (already processed)
    structfiles = dir(fullfile(outputdir, '*', outputname));  
    structsprocessed = {structfiles.name}; 
    
    % Remove filenames from loop iteration if they have a struct saved
    filesprocessed = strrep(structsprocessed, outputname, ".set");
    filenames = filenames(~ismember(filenames, filesprocessed));

    % Function to process FFT data from multiple files and save the results 
    parfor ffti = 1:length(filenames)
        try
            % Construct the full path to the file
            currentFile = fullfile(inputdir, filenames{ffti});
            EEG = pop_loadset('filename', filenames{ffti}, 'filepath', inputdir);

            % Run fftx2
            current_fftx = fftx2(EEG.data, EEG.srate, filenames{ffti});
    
            % Temporary struct to store data
            tempStruct = struct();
            tempStruct.filename = current_fftx.filename;
            tempStruct.hz = current_fftx.hz;
            tempStruct.powavg = current_fftx.powavg;
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
            afftx(ffti) = tempStruct;
            
    
        catch ME
            fprintf('Error processing file %s: %s\n', filenames{ffti}, ME.message);
        
        end
    
    end
        
    % Save the information using a for loop instead of parfor
    for afftxi = 1:length(afftx)
        % Index the full struct -_-
        current_afftx = afftx(afftxi);
        % create the save file na,e
        savefilename = fullfile(outputdir, strrep(current_afftx.filename, ".set", outputname));
        % save the struct individually
        save(savefilename, 'current_afftx');
    end

end

