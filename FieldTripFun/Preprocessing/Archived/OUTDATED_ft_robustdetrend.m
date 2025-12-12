function data = ft_robustdetrend(cfg, data)
%FT_ROBUSTDETREND Robust detrending EEG data to remove DC offset. As of
% right now the function is designed to only working with rsEEG data. This
% function basically uses the `nt_detrend()` to detrend the data robustly!
%
% INPUT
%   cfg.robustdetrend.concatenate  = 'yes' (default) or 'no'
%   cfg.robustdetrend.order        = 10 (default)
%   cfg.robust.demean              = 'yes' (default); centers the channels after detrending
%
%   data = an object with EEG data taht follows the FieldTrip framework
% Output
%   robust_detrended_data = A continuous dataset 

% Set up configuration defaults
cfg.robustdetrend = ft_getopt(cfg, 'robustdetrend', struct());
concatenate  = ft_getopt(cfg.robustdetrend, 'concatenate', 'yes');
order        = ft_getopt(cfg.robustdetrend, 'order', 10);
demean        = ft_getopt(cfg.robustdetrend, 'demnea', 'yes');

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Check to make sure NoiseTools functions have been downloaded
if ~exist('nt_detrend', 'file')
    error('NoiseTools required: http://audition.ens.fr/adc/NoiseTools/');
end

% Concatenate the data if they are trials (and specified as 'yes')
if strcmp(concatenate, 'yes')
    cfg = [];
    cfg.continuous = 'yes'; 
    data = ft_redefinetrial(cfg, data);
    fprintf('EEG data was concatenated succesfully');
end

% Extract the EEG data (one long continuous trial)
x = data.trial{:};

% Transpose the matrix (sample x channels)
x_t = x';

% Run the nt_detrend() function to do robust detrending
[x_t, w] = nt_detrend(x_t,order);

% Transpose the data back into channels x trials
x_detrended = x_t';

% Replace the original continuous trial with the detrended data
data.trial{1} = x_detrended;

% Demean the signal
if strcmp(demean, 'yes')
    cfg = [];
    cfg.demean = 'yes'; 
    data = ft_preprocessing(cfg, data);
    fprintf('EEG data was demeand succesfully');
end

end