
bandNames = {'delta', 'theta', 'beta', 'alpha'};  % Frequency bands
frequencyBands = [1, 4; 4, 8; 8, 13; 13, 30];  % [start, end] Hz for each band


function process_fft_data(bandNames, frexvc, fileNames, inputDir, outputDir)
    % Function to process FFT data from multiple files and save the results

    % Initialize struct array for storing results
    afftx = struct(); 

    % Iterate over files
    for ffti = 1:length(fileNames)
        try
            % Construct the full path to the file
            currentFile = fullfile(inputDir, fileNames{ffti});
            
            % Run fftx2 (you'll need to adapt this to your specific function)
            current_fftx = fftx2(newsig_info.data, srate, currentFile);

            % Save meaningful information into afftx structure
            afftx(ffti).filename = current_fftx.filename;
            afftx(ffti).hz = current_fftx.hz;
            afftx(ffti).powavg = current_fftx.powavg;

            % Find the indices for each frequency band
            fzi = zeros(size(frequencyBands, 1), 2);
            for bandIdx = 1:size(frequencyBands, 1)
                fzi(bandIdx, :) = dsearchn(afftx(ffti).hz', frequencyBands(bandIdx, :)');
            end
            
            % Store FB values and calculate mean power dynamically
            for bandIdx = 1:size(frequencyBands, 1)
                bandName = bandNames{bandIdx};
                afftx(ffti).(sprintf('%sFB', bandName)) = afftx(ffti).powavg(fzi(bandIdx, 1):fzi(bandIdx, 2));
                afftx(ffti).(sprintf('avg%s', bandName)) = mean(afftx(ffti).(sprintf('%sFB', bandName)));
            end
            
        catch ME
            % Display the error and continue with the next iteration
            fprintf('Error processing file %s: %s\n', fileNames{ffti}, ME.message);
            continue;  % Continue with the next file
        end
    end

    % Investigate the variance of power dynamically and save results
    for bandIdx = 1:length(bandNames)
        bandName = bandNames{bandIdx};
        bandAvgValues = [afftx.(sprintf('avg%s', bandName))];
        varianceValue = var(bandAvgValues);
        fprintf('Variance of %s: %.4f\n', bandName, varianceValue);
        
    end

    % View spread with histograms dynamically and save them
    for bandIdx = 1:length(bandNames)
        bandName = bandNames{bandIdx};
        figure;
        histogram([afftx.(sprintf('avg%s', bandName))], 15);
        xlabel(sprintf('Average %s Power', bandName));
        ylabel('Frequency');
        title(sprintf('Histogram of Average %s Power', bandName));
        
        % Save the histogram figure
        saveHistFile = fullfile(outputDir, sprintf('%s_histogram.png', bandName));
        saveas(gcf, saveHistFile);
        close(gcf);  % Close the figure to avoid memory overload
    end
end
