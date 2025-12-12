function ft_quickplot3(X)
% FT_QUICKPLOT3 Plots rows as channels (centered)
%
% INPUT
%   X = matrix (chans x samples); any 
% size but works best with single trials.

% Prepare the data
X_c = X - mean(X, 2); % Remove mean per channel
offset = 3 * std(X(:));
channel_offset = (0:size(X,1)-1)' * offset;
stacked_data = X_c + channel_offset;

% Generate the plot
plot(stacked_data', 'k', 'LineWidth', 1);
xlabel('Sample Number'); ylabel('Amplitude (stacked)');
grid on;

end