function ft_quickplot1(X)
% FT_QUICKPLOT1 Creates a heat map
%
% INPUT
%   X = matrix (chans x samples); any size but 
%           works best with single trials.


imagesc(X);
colorbar; colormap(jet);
xlabel('Samples');
ylabel('Electrodes');

end