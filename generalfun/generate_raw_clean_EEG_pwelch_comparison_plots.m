% generateEEGPowerHeatmaps
% Compares raw vs cleaned EEG files using pwelch and saves side-by-side heatmap plots.
%
% Inputs:
%   rawDir     - Directory containing raw .set EEG files
%   cleanDir   - Directory containing cleaned .set EEG files
%   outputDir  - Directory to save the resulting heatmap comparison plots

function generate_raw_clean_EEG_pwelch_comparison_plots(rawDir, cleanDir, outputDir, raw_exten, cleaned_exten, Quality)

    % Create output directory if it doesn't exist
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % Get raw file list
    rawFiles = dir(fullfile(rawDir, ['*',raw_exten]));

    % Loop through all raw files
    for i = 1:length(rawFiles)

        % Extract current Quality
        current_Quality = char(Quality(i));
       
        % Extract current raw file and processed file
        current_raw = rawFiles(i).name;
        current_cleaned = strrep(current_raw, raw_exten, cleaned_exten);
        
        % Check to see if a cleaned version exists- or else it will crash
        % the loop
        if ~isfile([cleanDir,current_cleaned])
            fprintf('Skipping: no clean file exists for: %s', current_raw)
            continue; 
        end

        % Load datasets
        EEG_raw = pop_loadbv(rawDir, current_raw);
        EEG_clean = pop_loadset('filename', current_cleaned, 'filepath', cleanDir);

        % Settings for pwelch
        win = hamming(512);
        noverlap = 256;
        nfft = 512;
        fs = EEG_raw.srate;

        % Identify which channels are in common between the two files
        rawLabels = string({EEG_raw.chanlocs.labels});
        cleanedLabels = string({EEG_clean.chanlocs.labels});

        sharedLabels = intersect(rawLabels, cleanedLabels, 'stable');
        nShared = numel(sharedLabels);

        % Create empty matrices to store pwelch outcome for each channel
        P_raw_all = zeros(nShared, nfft/2 + 1);    
        P_clean_all = zeros(nShared, nfft/2 + 1);

        % Compute power spectra for channels that are shared for both
        % recordings
        for idx = 1:nShared
            % Get the index of the shared label for raw and clean data
            ch_raw = find(rawLabels == sharedLabels(idx));
            ch_clean = find(cleanedLabels == sharedLabels(idx));

            % Extract current shared label for raw and cleaned data
            [P_raw, F_raw] = pwelch(double(EEG_raw.data(ch_raw,:)), win, noverlap, nfft, fs);
            [P_clean, F_cleaned] = pwelch(double(EEG_clean.data(ch_clean,:)), win, noverlap, nfft, fs);
            
            % Store the pwelch output into the empty matrix
            P_raw_all(idx, :) = P_raw;
            P_clean_all(idx, :) = P_clean;
        end

        % Create a unique color for each channel
        cmap = lines(nShared);  
        
        % Create figure without displaying it
        fig = figure('Visible', 'off'); % <--- This prevents showing the figure window
        
        % RAW subplot
        subplot(2,1,1)
        hold on
        for idx = 1:nShared
            plot(F_raw, P_raw_all(idx,:), 'LineWidth', 1, 'Color', cmap(idx,:));
        end
        hold off
        set(gca, 'xlim', [0 30], 'ylim', [0 1.05*max(P_raw_all(:))])
        xlabel('Frequency (Hz)')
        ylabel('PSD (µV² / Hz)')
        title(['RAW Power Spectrum - All Channels'], 'FontSize', 12)
        
        % CLEANED subplot
        subplot(2,1,2)
        hold on
        for idx = 1:nShared
            plot(F_cleaned, P_clean_all(idx,:), 'LineWidth', 1, 'Color', cmap(idx,:));
        end
        hold off
        set(gca, 'xlim', [0 30], 'ylim', [0 1.05*max(P_clean_all(:))])
        xlabel('Frequency (Hz)')
        ylabel('PSD (µV² / Hz)')
        title(['CLEANED Power Spectrum - All Channels - Quality: ' current_Quality], 'FontSize', 12)
        
        % Add a legend
        legend(sharedLabels, ...
       'Location', 'eastoutside', ...
       'FontSize', 6, ...
       'NumColumns', 2); 

        % Save figure to file
        save_plot_name = strrep(current_raw, raw_exten, ['_comparison_plot_' current_Quality '.png']);
        outName = fullfile(outputDir, save_plot_name);
        saveas(fig, outName);
        
        % Close figure to free memory
        close(fig);

    end
end