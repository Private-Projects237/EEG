% INPUT
% loadedStructs: The .mat files structure loaded 
% csvSavePathway: The pathway to save the table as a .csv
%
% OUPUT (table):
% filename: the name of the original EEG file
% Electrodes: All the electrodes in the recording
% DeltaPwr: Delta absolute power for all the electrodes
% ThetaPwr: Theta absolute power for all the electrodes
% AlphaPwr: Alpha absolute power for all the electrodes
% BetaPwr: Beta absolute power for all the electrodes
%
% Description: Takes the output from the extract_eeg_freqband_power_welchx()
% function, which are basically .mat files with a plethera of information,
% and saves absolute power for specified frequency bands for all electrodes
% as a .csv file.
%
% Example:
% FBpow(loadedStructs, csvSavePathway)

function FBpow(loadedStructs, csvSavePathway)

    % Save loadedStructs into an object
    awelchx = loadedStructs;

    for ii = 1:length(awelchx)
        % Create a tablethat contains electrode information and absolute power only
        FileName = awelchx(ii).filename;
        Electrodes = awelchx(ii).chanlabl;
        DeltaPwr = awelchx(ii).absdelta;
        ThetaPwr = awelchx(ii).abstheta;
        AlphaPwr = awelchx(ii).absalpha;
        BetaPwr = awelchx(ii).absbeta;
        
        % Create the table
        ElecPwrTable = table(Electrodes, DeltaPwr, ThetaPwr, AlphaPwr, BetaPwr);
        
        % Modify the name of the file to be saved as
        FileName = strrep(FileName, '.set', '_elec_top.csv');
        
        % Save the table
        writetable(ElecPwrTable, append(csvSavePathway, FileName));
    
    end
end