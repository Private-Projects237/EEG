% INPUT
% filedir: The directory to where the .mat files are (character scalar)
% matfiles: structure that contains .mat file names (dir structure)
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
% Description: Loads in the .mat files of interest and then
% combines them, producing one struct. This code is
% quick but can be slow on the server!
%
% Example:
% loadedStructs = loadStructs2(matfiles)

function [loadedStructs] = loadStructs2(filedir, matfiles)
    
    % Initialize an empty struct array
    loadedStructs = [];
    
    % Loop through files
    for i = 1:length(matfiles)
        % Load each file
        data = load(fullfile(filedir, matfiles(i).name));
        % Append to struct array
        loadedStructs = [loadedStructs, data.current_awelchx];
    end

end
