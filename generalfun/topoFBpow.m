% INPUT
% loadedStructs: The directory to where the .mat files are (character scalar)
% nbchanstruct: output from using dir, contains .mat file names (dir structure)
% avgFB: Same names as the .mat files being loadaed- tedisu (character vector)
%
% OUPUT (table):
% filename: the name of the original EEG file
% avgFB x topography
%
% Description: Takes in the output from 'loadStructs.m'. It creates
% a comprehensive table with the different combinations of topography
% and frequency bands that are avaiable in the loadedStructs and the
% nbchanstruct. The output is ready to be loaded into R for analysis. 
% This code was hard coded by my but then soft codded by deepseek. The 
% output from this soft coded version was the same as that of the hard
% coded version that is now archived. 
%
% Example:
% nbchanAvgPow = nbchanFBpow(loadedStructs, nbchanstruct, avgFB)

function [topographyFBAvgPow] = topoFBpow(loadedStructs, nbchanstruct, avgFB)
    % Preallocate a table to store results
    results = table();
    
    % Loop through each struct
    for strcti = 1:length(loadedStructs)
        currentStruct = loadedStructs(strcti);
        currentfilename = currentStruct.filename;
        chanlabl = currentStruct.chanlabl;
        
        % Initialize a struct to store averages for this file
        fileAverages = struct('filename', currentfilename);
        
        % Loop through each region in nbchanstruct
        regions = fieldnames(nbchanstruct);
        for regioni = 1:length(regions)
            region = regions{regioni};
            regionChannels = nbchanstruct.(region);
            regionIndx = ismember(chanlabl, regionChannels);
            
            % Loop through each frequency band
            for frexbndi = 1:length(avgFB)
                band = avgFB{frexbndi};
                bandData = currentStruct.(band); % Dynamic field access
                bandAverage = mean(bandData(regionIndx)); % Calculate mean
                
                % Store the result in the fileAverages struct
                fieldName = sprintf('%s_%s', region, band);
                fileAverages.(fieldName) = bandAverage;
            end
        end
        
        % Convert the struct to a table row and append to results
        results = [results; struct2table(fileAverages, 'AsArray', true)];
    end
    
    % Assign the results table to the output variable
    topographyFBAvgPow = results;
end