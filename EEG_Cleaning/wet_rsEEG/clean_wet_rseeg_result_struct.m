function result = clean_wet_rseeg_result_struct(fileName)
    % Ensure result is initialized with an empty struct and predefined fields
    result = struct();

    % To save the name of the function used
    result.usedFunction = {"-"};
    
    % Populate the struct with default values
    result.FileName = fileName;
    result.Date = '-';
    result.Rank_BeforeCleaning = NaN;
    result.StartingChan = NaN;
    result.avgAmpRange1 = NaN;

    % Removing DC offset (detrending)
    result.removedDCOffset = 'false';
    result.avgAmpRange2 = NaN;

    % Band Pass Filtering
    result.BandPassFilt = '-';
    result.avgAmpRange3 = NaN;
    
    % Bad channel detection fields (convential function)
    result.AllBadChannels = {"-"};  
    result.NumAllBadChannels = NaN;
    result.InterpolationDone = 'false';
    result.avgAmpRange4 = NaN;
    
    % Re-referencing and downsampling details
    result.RereferencedTo = "-";
    result.avgAmpRange5 = NaN;
    result.DownsampledTo = NaN;
    
    % PCA dimension selection for ICA
    result.PCA_Dimension = NaN;
    
    % ICA processing fields
    result.ICA_Done = 'false';
    result.ICA_Saved = 'false';
    result.ICLabel_Done = 'false';
    
    % IC total number classification (number of components for each category; top 20)
    result.TotalBrainComponents = NaN; % class 1 (Not noise obviously)
    result.TotalMuscleComponents = NaN; % class 2
    result.TotalEyeComponents = NaN; % class 3
    result.TotalHeartComponents = NaN; % class 4
    result.TotalLineComponents = NaN; % class 5
    result.TotalChannelComponents = NaN; % class 6
    result.TotalOtherComponents = NaN; % class 7 (optional)

    % IC order classification (component number in order)
    result.BrainComponentsIdx = {"-"};  
    result.MuscleComponentsIdx = {"-"}; 
    result.EyeComponentsIdx = {"-"}; 
    result.HeartComponentsIdx = {"-"}; 
    result.LineComponentsIdx = {"-"}; 
    result.ChannelComponentsIdx = {"-"}; 
    result.OtherComponentsIdx = {"-"}; 
    
    % Number of components removed and confirmation of removal
    result.ComponentsRemoved = NaN;
    result.ComponentsRemovalDone = 'false';
    result.avgAmpRange6 = NaN;

    % Length of the recording overall
    result.EEGLengthSec = NaN; 

    % EEG data segment QC report
    result.SegTotalNum = NaN;
    result.SegOverlapPercent = NaN;
    result.SegTotalNumOverlap = NaN;
    result.SegGoodNum = NaN;
    result.SegBadNum = NaN;
    result.SegPropGood = NaN;

    % Rank and AvgAmpRange after cleaning
    result.Rank_AfterCleaning = NaN;

    % File saved as
    result.savedFile = '-';
    
    % Default error message
    result.ErrorMessage = 'No Error';  
end
