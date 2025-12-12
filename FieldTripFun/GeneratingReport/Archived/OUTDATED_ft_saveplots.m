function plotcollector = ft_saveplots(cfg, data)
% FT_SAVEPLOTS Collects all open figures, saves them as PNGs, and closes them.
%
% Inputs:
%   cfg.savingplots.initialindx    = 0 (default); starts plot naming at
%       this value to keep summary plots at the top. It should be a one
%       time thing. 
%   cfg.savingplots.plotcollector  = An empty cell array or one that contains
%       figures saves within it (To keep track of image numbering)
%   cfg.savingplots.outputdir      = Directory to save the PNGs
%   cfg.savingplots.summary        = 'no' (default);
%
% Outputs:
%   1. plotcollector: Updated cell array with image file paths
%   2. saves PNG at the specified location

% Check configuration for correct parameters
cfg = ft_checkconfig(cfg, 'required', {'savingplots'});

% Set up configuration defaults
cfg.savingplots = ft_getopt(cfg, 'savingplots', struct());
initialindx     = ft_getopt(cfg.savingplots, 'initialindx', 0);
plotcollector   = ft_getopt(cfg.savingplots, 'plotcollector', {});
outputdir       = ft_getopt(cfg.savingplots, 'outputdir', []);
summary         = ft_getopt(cfg.savingplots, 'summary', 'no');

% Validate input data
data = ft_checkconfig(data, 'required', {'label', 'trial', 'time', 'fsample', 'sampleinfo'});

% Find all open figures
figHandles = findall(0, 'Type', 'figure');
figHandles = flip(figHandles);

    % Loop through each figure to save as PNG and collect title
    for i = 1:length(figHandles)
        
        % Add a small text to describe the file name
        if isempty(data.cfg.preproc.history)
            name = 'rawdata';
        elseif strcmp(summary, 'yes')
            name = 'summary';
        else 
            name = data.cfg.preproc.history{end}.name;
        end

        % Generate the file name
        file_name = sprintf('plot_%03d_%s.png', length(plotcollector) + initialindx + 1, name);
       
        % Create a full pathway to save the .png
        imgFile = fullfile(outputdir, file_name);
        
        % idk what this does 
        print(figHandles(i), '-dpng', imgFile);

        % Save image path and title
        plotcollector{end+1} = imgFile; pause(0.1) % 100 ms wait

        % Close figure to free memory
        close(figHandles(i));
    end
end