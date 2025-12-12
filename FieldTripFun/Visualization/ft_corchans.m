function ft_corchans(cfg, data)
%FT_CORCHANS Returns a bivariate correlation matrix of all the channels in
% the EEG data. Must have the EEG data saved in a FieldTrip framework with
% information for labels and trials.
%
% cfg is optional for this function
%
% Use as:
%   ft_corchans(cfg, data) or ft_corchans('data', x) | ft_corchans('data', data)
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within


% Default configuration
data = ft_checkconfig(data, 'required', {'trial', 'label'});

% Setting short cut variables from cfg
visibleplots = 'yes';
saveplots    = 'no';
main = 'no';

% Overrite configuration if saveplot field (structure) specified
if isfield(cfg, 'saveplots')
    visibleplots = cfg.saveplots.visibleplots;
    saveplots    = cfg.saveplots.saveplots;
    main         = cfg.saveplots.main;
    skip         = cfg.saveplots.skip;
    plotfolder   = cfg.saveplots.plotfolder;
end

% Specify whether the plot is visible or not
if strcmp(visibleplots, 'yes'); Show = 'on'; else; Show = 'off'; end

% Short cut variables
trial = data.trial;
label = data.label;

% Concatenate all trials
one_trial = cat(2, trial{:});

% Calculate the correlation matrix
R = corrcoef(one_trial');
R = round(R, 3);

% Print the correlation table
fprintf('\nCorrelation (2 decimals):\n');
disp(array2table(round(R,2), 'VariableNames', label, 'RowNames', label));

% ——— LOWER-TRIANGLE ONLY: RED (+), BLUE (-), UPPER = BLANK ———
fig = figure('Visible', Show, 'Color','w','Name','Channel Correlations');
ax = axes; axis square; hold on;

n = length(label);
set(ax, 'XLim',[0.5 n+0.5], 'YLim',[0.5 n+0.5], ...
        'YDir','reverse', 'XTick',1:n, 'YTick',1:n, ...
        'XTickLabel',label, 'YTickLabel',label, ...
        'XTickLabelRotation',45);

% Red-White-Blue colormap
cmap = [linspace(0,1,128)' linspace(0,0.5,128)' ones(128,1);     % blue
        1 1 1;                                                  % white
        ones(128,1) linspace(0.5,0,128)' linspace(0,0,128)'];   % red
colormap(cmap);

% DRAW ONLY LOWER TRIANGLE
for i = 1:n
    for j = 1:i-1
        val = R(i,j);
        cidx = round((val + 1)/2 * 255) + 1;
        cidx = max(1, min(256, cidx));
        color = cmap(cidx,:);
        
        patch([j-0.5 j+0.5 j+0.5 j-0.5], ...
              [i-0.5 i-0.5 i+0.5 i+0.5], ...
              color, 'EdgeColor','k','LineWidth',0.5);
        
        if n <= 20
            txtcol = 'k'; if abs(val) > 0.7, txtcol = 'w'; end
            text(j, i, sprintf('%.2f',val), ...
                 'Horiz','center','Vert','middle', ...
                 'Color',txtcol,'FontWeight','bold');
        end
    end
end

% FIXED COLORBAR — 100% WORKING
cb = colorbar;
cb.Ticks = 0:0.25:1;
cb.TickLabels = {'-1','-0.5','0','0.5','1'};
cb.Label.String = 'Correlation';

title('Channel Correlation Matrix (Heatmap)','FontWeight','bold');
box on;

% If plots are to be saved then save them
if strcmp(saveplots, 'yes')
    cfg_sp = [];
    cfg_sp.fig = fig;
    cfg_sp.plotname = 'corchans';
    cfg_sp.main = main;
    cfg_sp.skip = skip;
    cfg_sp.plotfolder = plotfolder;
    savehandlefig(cfg_sp)
end 

end