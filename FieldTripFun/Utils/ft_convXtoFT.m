function data = ft_convXtoFT(X, fs)
%FT_CONVXTOFT: Converts an X matrix into a FieldTrip data structure.
% This is great if you need to use additional FieldTrip functions that wil
% only work on a FieldTrip dataset. 
%
% USAGE
%   data = ft_convXtoFT(X)
%

% Check is a sampling rate was specified
if nargin < 2 || isempty(fs)
    fs = 500;
end

% Generate a fake 'data' FieldTrip structure
[nChannels, nSamples, nTrials] = size(X);

% Channel labels (auto-generate if unnamed)
chan_labels = cell(1, nChannels);
for i = 1:nChannels
    chan_labels{i} = sprintf('chan%d', i);
end

% Build the raw structure
data = [];
data.label   = chan_labels';         % {1×nChannels cell}
data.trial   = cell(1, nTrials);    % {1×nTrials cell}
data.time    = cell(1, nTrials);    % {1×nTrials cell}
data.fsample = fs;                  % Scalar
data.sampleinfo = [1 size(X,2)];

% Create the time vector
time_per_trial = (0:nSamples-1)/fs;

% Introduce the data into time and trial cells
for i = 1:nTrials
    data.trial{i} = squeeze(X(:, :, i));  % [nSamples × nChannels]
    data.time{i}  = time_per_trial;       % Same for all trials
end

end