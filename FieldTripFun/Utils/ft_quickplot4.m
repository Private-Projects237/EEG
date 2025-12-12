function ft_quickplot4(X)
% FT_QUICKPLOT4 Plots centered stacked channels
%
% INPUT
%   X = matrix (chans x samples); any 
% size but works best with single trials.

% Center the channels
X_c = X - mean(X,2);
t = 1:size(X,2);

% Create the stack plot
plot(t, X_c', 'k','LineWidth',1.1); hold on;
colormap(parula(size(X,1)));   % 1 color per channel
grid on; box on;
xlabel('Sample Number'); ylabel('Amplitude (µV)');
title('Stacked Channels (Raw Units)', 'FontWeight','bold');
hold off;

end
