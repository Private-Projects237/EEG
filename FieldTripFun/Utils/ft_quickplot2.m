function ft_quickplot2(X)
% FT_QUICKPLOT2 Creates a heat map (Z-scored)
%
% INPUT
%   X = matrix (chans x samples); any 
% size but works best with single trials.

% Convert matrix into a vector
v = X(:);
z = zscore(v);
Z = reshape(z, size(X));

% Generate the plot
imagesc(Z);  % Auto-scale per channel
colorbar; colormap(parula);
xlabel('Samples'); ylabel('Electrodes');

end
