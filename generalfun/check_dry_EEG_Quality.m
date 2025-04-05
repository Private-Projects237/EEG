% INPUT: 
% main_QC_excel: an excel file with QC data of the dry EEG recordings. It
% is a byproduct of the clean_dry_rsEEG and organizing_QC functions. 


function [Good_Recordings, Bad_Recordings, Quality] = check_dry_EEG_Quality(main_QC_excel, BadChnThres, ASRIntrpThres, AvgAmp2Thres)

    % Save main_QC_excel as T
    T = main_QC_excel; 

    % Create a new variable called Quality and let the value all be "bad"
    T.Quality = repmat("Bad", height(T),1);

    % Using the thresholds, obtain the index of recordings that are
    % actually "Good" for not going above any of the thresholds. 
    GoodIndx = T.NumAllBadChannels <= BadChnThres & T.Proportion_Altered <= ASRIntrpThres & T.avgAmpRange2 <= AvgAmp2Thres; 

    % Using this index, extract the files that are "Good" and those that are
    % "Bad" and saved them in their own object
    Good_Recordings = T.FileName(GoodIndx);
    Bad_Recordings = T.FileName(~GoodIndx);

    % Return Quality vector (can be used for plottin)
    T.Quality(GoodIndx) = "Good";
    Quality = T.Quality;

    % Summary statistics
    total = height(T);
    nGood = numel(Good_Recordings);
    nBad  = numel(Bad_Recordings);

    pctGood = round((nGood / total) * 100,2);
    pctBad  = round((nBad  / total) * 100,2);

    % Output
    fprintf("\n📊 EEG Recording Quality Summary\n")
    fprintf("────────────────────────────────────\n")
    fprintf("Total recordings:      %3d\n", total)
    fprintf("✅ Good recordings:     %3d (%.1f%%)\n", nGood, pctGood)
    fprintf("❌ Bad recordings:      %3d (%.1f%%)\n", nBad,  pctBad)

end