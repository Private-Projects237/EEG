% INPUT
% filedir: The directory to where the .mat files are (character scalar)
% matfiles: output from using dir, contains .mat file names (dir structure)
% strctfieldnames: Same names as the .mat files being loadaed- tedisu (character vector)
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
% Description: Loads in the .mat files of interest. This code is
% quick but can be slow on the server!
%
% Example:
% loadedStructs = loadStructs(filedir, matfiles, strctfieldnames)

function [loadedStructs] = loadStructs(filedir, matfiles, strctfieldnames)
    
    % Initialize a struct array with the desired fields
    loadedStructs = struct('filename', {}, strctfieldnames{:}, {});
    
    % make it work with both fftx2 and welchx2
    if contains(matfiles(1).name, 'welchx2')
        structv = 'current_awelchx';
    else
        structv = 'current_afftx';
    end

    % Loop through each file and populate the struct array
    for i = 1:numel(matfiles)
        % Load the .mat file
        filePath = fullfile(filedir, matfiles(i).name);
        tempData = load(filePath); % Load the file into a temporary struct
        currentStruct = tempData.(structv); % Extract the structure

        % Populate the new struct array with the data
        loadedStructs(i).filename = matfiles(i).name; % Store the filename
        for field = strctfieldnames
            loadedStructs(i).(field{1}) = currentStruct.(field{1}); % Dynamic field assignment
        end
           
    end

end
