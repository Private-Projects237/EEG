function result = clean_dry_rseeg_result_struct(fileName)
    % Ensure result is initialized with an empty struct and predefined fields
    result = struct();

    % To save the name of the function used
    result.usedFunction = {"-"};
    
    % Populate the struct with default values
    result.FileName = fileName;
    result.Rank_BeforeCleaning = NaN;
    result.StartingChan = NaN;
    result.BandPassFilt = '-';
    result.avgAmpRange1 = NaN;
    
    % Bad channel detection fields
    result.BadChannels_Poor_Corr = {"-"};  
    result.NumBadChannels_Poor_Corr = NaN;
    result.BadChannels_SD_Seg = {"-"};  
    result.NumBadChannels_SD_Seg = NaN;
    result.AllBadChannels = {"-"};  
    result.NumAllBadChannels = NaN;
    result.InterpolationDone = 'false';
    
    % Recording length before and after ASR
    result.RecordingLength_BeforeASR = NaN;
    result.RecordingLength_AfterASR = NaN;
    
    % Proportion of data retained after ASR (rounded to 3 decimal places)
    result.ASR_Proportion_Retained = NaN;
    result.asrDiffThreshold = NaN;
    result.Proportion_Altered = NaN; 
    
    % Re-referencing and downsampling details
    result.RereferencedTo = "-";
    result.DownsampledTo = NaN;
    
    % PCA dimension selection for ICA
    result.PCA_Dimension = NaN;
    
    % ICA processing fields
    result.ICA_Done = 'false';
    result.ICLabel_Done = 'false';
    
    % IC classification (artifact components)
    result.EyeComponents = NaN;
    result.MuscleComponents = NaN;
    result.HeartComponents = NaN;
    result.LineComponents = NaN;
    result.ChannelComponents = NaN;
    
    % Number of components removed and confirmation of removal
    result.ComponentsRemoved = NaN;
    result.ComponentsRemovalDone = 'false';

    % Rank and AvgAmpRange after cleaning
    result.Rank_AfterCleaning = NaN;
    result.avgAmpRange2 = NaN;
    
    % Default error message
    result.ErrorMessage = 'No Error';  
end
