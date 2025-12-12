function savehandlefig(cfg_sp)
% SAVEHANDLEFIG  This is a helper function that is used to save generated
% plots within preprocessing functions.
%
%   cfg_sp = cfg saveplot
%
% INPUT
%   cfg.fig          = Object that contains the figure (fig) 
%   cfg.plotname     = The name of the function that generated the plot - will
%       be used as the name of the PNG.
%   cfg.main         = 'no' (default); indicates whether these are main
%       plots that will be saved as initial (skip must be = 0)
%   cfg.skip         = When naming plot- how many values are skipped
%   cfg.plotfolder   = Pathway to save the PNG in

% Check configuration
cfg_sp = ft_checkconfig(cfg_sp, 'required', {'fig', 'plotname', 'plotfolder'});

% Extract the parameters
fig        = cfg_sp.fig;
plotname   = cfg_sp.plotname;
main       = ft_getopt(cfg_sp, 'main', 'no');
skip       = ft_getopt(cfg_sp, 'skip', []);
plotfolder = cfg_sp.plotfolder;
     
% Check to see if a PNG already exists and create the plot number 
if isempty(dir(fullfile(plotfolder, '*.png')))
    plotnum = 1 + skip;
elseif strcmp(main, 'yes')
    plotnum = numel(dir(fullfile(plotfolder, '*main*.png'))) + 1 + skip;
else
    plotnum = numel(dir(fullfile(plotfolder, '*.png'))) + 1 + skip;
end

% Generate the name of the PNG 
if strcmp(main, 'no')
    PNGname = sprintf('%03d_%s.png', plotnum, plotname);
elseif strcmp(main, 'yes')
    PNGname = sprintf('%03d_%s_main.png', plotnum, plotname);
end

% Save the plot generated as a PNG
filename = fullfile(plotfolder, PNGname);
exportgraphics(fig, filename, 'Resolution', 300);
fprintf('Saved → %s\n', filename);

% Close the figure (save up space)
close(fig);
    
end
