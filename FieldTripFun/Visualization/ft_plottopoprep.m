function [topo_dat, data] = ft_plottopoprep(data)
% FT_PLOTTOPOPREP Takes a dataset and creates a new struct with info needed
% to to use `ft_plottopo()`. If we use `ft_plottopo()` directly it will
% likely crash for some unknown reason as of right now. 
%
% Usage:
%   ft_plotsummarystats(data)
%
% Input:
%   data.label       = A cell array of the names of the channels
%   data.avgtime     = A vector of average amplitudes for each channel in the time domain
%   data.avgfft      = A vector of average amplitudes for each channel in the frequency domain
%   data.avgdelta    = A vector of average delta amplitude for each channel
%   data.avgtheta    = A vector of average theta amplitude for each channel
%   data.avgalpha   = A vector of average alpha amplitude for each channel
%   data.avgbeta    = A vector of average beta amplitude for each channel
%
% Output:
%   topo_dat = A new structure with the fields from above
%   data = The input data object with the fields removed
%
% Validate inputs
data = ft_checkconfig(data, 'required', {'label', ...
                                         'avgtime', ...
                                         'avgfft', ...
                                         'avgdelta', ...
                                         'avgtheta', ...
                                         'avgalpha', ...
                                         'avgbeta'});

% Create a new structure 'topo_dat' with this information
topo_dat = struct();
topo_dat.label = data.label;
topo_dat.avgtime = data.avgtime;
topo_dat.avgfft = data.avgfft;
topo_dat.avgdelta = data.avgdelta;
topo_dat.avgtheta = data.avgtheta;
topo_dat.avgalpha = data.avgalpha;
topo_dat.avgbeta= data.avgbeta;

% Remove this field information from the original dataset 'data'
data = rmfield(data, 'avgtime'); data = rmfield(data, 'fft');
data = rmfield(data, 'dimord'); data = rmfield(data, 'avgfft');
data = rmfield(data, 'avgdelta'); data = rmfield(data, 'avgtheta');
data = rmfield(data, 'avgalpha'); data = rmfield(data, 'avgbeta');

end


