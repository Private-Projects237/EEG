function [zMatrix] = ft_robustzmatrix(cfg, data)
% FT_ROBUSTZMATRIX Takes in segmented EEG data and returns robust z-scores
% of variance for each channel x trial combination. Thus, the returned
% robust z-score matrix will have the same number as rows as the dataset
% but the number of columns will be equal to the number of produced trials.
% If the data are already segment then leave the first two parameters
% blank.
%
% INPUT
%   data = A FieldTrip data structure
%
% INPUT
%   cfg.robustzmatrix.segmentdat   = 'yes' or 'no' (default = no);
%   cfg.robustzmatrix.segseclength = 2 (recommended);
%   cfg.robustzmatrix.type         = 'all' or 'within'; 'all' uses all
%       variances to compute the robust z-scores while 'within' calculates 
%       them within rows (channels).

% Check configuration for correct parameters
cfg = ft_checkconfig(cfg, 'required', {'robustzmatrix'});

% Set up configuration defaults
cfg.robustzmatrix = ft_getopt(cfg, 'robustzmatrix', struct());
segmentdat     = ft_getopt(cfg.robustzmatrix, 'segmentdat', 'no');
segseclength   = ft_getopt(cfg.robustzmatrix, 'segseclength', 2);
type           = ft_getopt(cfg.robustzmatrix, 'type', 'all');

% Segment the EEG data is specified
if strcmp(segmentdat, 'yes')
    cfg = [];
    cfg.length  = segseclength; % segment length in seconds
    cfg.overlap = 0;            % 0 for non-overlapping (100% = fully overlapping)
    data_seg = ft_redefinetrial(cfg, data);
else
    % Save the data into a new object
    data_seg = data;
end

% Convert the segmented data into a 3D (EEG) type matrix
EEG = cat(3, data_seg.trial{:}); % chan x samples x trials
chan_trial_var = squeeze(var(EEG, [], 2));

% Robust z-scoring
if strcmp(type, 'all')
    median_var = median(chan_trial_var(:));
    MAD_var    = mad(chan_trial_var(:), 1);
    zMatrix   = (chan_trial_var - median_var) / (1.4826 * MAD_var);
    
elseif strcmp(type, 'within')
    median_var = median(chan_trial_var, 2); 
    MAD_var = median(abs(chan_trial_var - median_var), 2); 
    zMatrix = (chan_trial_var - median_var) ./ (1.4826 * MAD_var);
end


end