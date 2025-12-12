function data_int = ft_channelinterpolate(cfg, data)
% FT_CHANNELINTERPOLATE This function is literally the FieldTrip base 
% `ft_channelrepair()` function, except here we added some additional lines
% of code so we can log the channel interpolation within `ft_logstep()`
%
% WARNING: Must have neighbours and must have `.elec`
%
% INPUT
%   cfg.chaninterp.badchannel     = (e.g. {'Fp1'}); cell array of channel lables
%   cfg.chaninterp.method         = 'weighted' (default)
%   cfg.chaninterp.orig_labels    = data.label (no default);
%   cfg.chaninterp.elec_file      = which('standard_1005.elc');
%   cfg.chaninterp.intpchanplot   = 'no' (default);
%   cfg.chaninterp.log            = 'no' (default);
%
%   cfg.neighbours    = neighbour structure from ft_prepare_neighbours **REQUIRED**
%
% INPUT (for saving) - uses savehandlefig() function
%   cfg.saveplots.visibleplots = 'yes' (default);
%   cfg.saveplots.saveplots    = 'no' (default);
%   cfg.saveplots.main         = 'no' (default); Includes 'main' in PNG name
%   cfg.saveplots.skip         =  []; Numbers to skip when naming PNG
%   cfg.saveplots.plotfolder   =  []; A pathway that PNGs will be saved within

% Save the original configuration
cfg_org = cfg; 

% Validate inputs
cfg = ft_checkconfig(cfg, 'required', {'chaninterp'});

% Safety check, neighbours structure needs to be present 
if ~isfield(cfg.chaninterp, 'neighbours')
    ft_error('cfg.neighbours is required – run ft_prepare_neighbours() first.');
end

% Save neighbours as an object
neighbours   =  cfg.chaninterp.neighbours; 

% Save original channels as an object
orig_labels = cfg.chaninterp.orig_labels;

% Set up configuration defaults
cfg.chaninterp = ft_getopt(cfg, 'chaninterp', struct());
badchannel     = ft_getopt(cfg.chaninterp, 'badchannel', []);
method         = ft_getopt(cfg.chaninterp, 'method', 'weighted');
elec_file      = ft_getopt(cfg.chaninterp, 'elec_file', which('standard_1005.elc'));
intpchanplot   = ft_getopt(cfg.chaninterp, 'intpchanplot', 'no');
log            = ft_getopt(cfg.chaninterp, 'log', 'no');

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

% Interpolate channels that are bad
if ~isempty(badchannel)
    % Interpolate bad channels using `ft_channelrepair()`
    cfg_intpchan = [];
    cfg_intpchan.badchannel     = badchannel;
    cfg_intpchan.method         = method;
    cfg_intpchan.neighbours     = neighbours;
    
    % Interpolate the bad channels
    data_int = ft_channelrepair(cfg_intpchan, data);
    
    % New channel number
    newChanNum = numel(data_int.label);
    
    % Update .hdr file manually
    data_int.hdr.nChans = numel(data_int.label);
    data_int.hdr.label  = data_int.label;  % update labels
    data_int.hdr.chanunit = repmat({'uV'}, newChanNum, 1);  % or correct units
    data_int.hdr.chantype = repmat({'eeg'}, newChanNum, 1); % or appropriate types
    data_int.hdr.Fs = data_int.fsample;
    
    % Reorder to match original (it works but causes an error?)
    [~, loc_orig] = ismember(orig_labels, data_int.label);
    data_int.label = data_int.label(loc_orig);
    for tr = 1:length(data_int.trial)
        data_int.trial{tr} = data_int.trial{tr}(loc_orig, :);
    end
    
    % Reintroduce the position information
    data_int.elec = ft_read_sens(elec_file);

end 

% If there are no channels to interpolate
if isempty(badchannel)
    data_int = data;
end


if strcmp(intpchanplot, 'yes')
    % Get the index of the bad channel
    if ~isempty(badchannel)
        bandchannel_idx = find(ismember(data_int.label, badchannel));
    else
        bandchannel_idx = [];
    end
    
    % Convert the FieldTrip data into a single matrix
    X = cat(2, data_int.trial{:});
    
    % Prepare the data
    X_c = X - mean(X, 2); % Remove mean per channel
    offset = 20 * median(abs(X(:) - median(X(:)))); % Spaces out channels
    channel_offset = (0:size(X,1)-1)' * offset;
    stacked_data = X_c + channel_offset;
    
    % Generate the plot
    fig = figure('Visible', Show, 'Position', [100 100 1000 800]);
    hold on;   % Important: we plot channel-by-channel
    
    % Default color for good channels (close to your original black)
    good_color = [0.3 0.3 0.3];   % dark gray
    
    for ch = 1:size(X,1)
        if ismember(ch, bandchannel_idx)
            % Flat channels → blue
            plot(stacked_data(ch,:), 'Color', 'magenta', 'LineWidth', 1.8);
        else
            % Everything else → normal dark gray
            plot(stacked_data(ch,:), 'Color', good_color, 'LineWidth', 1);
        end
    end
    
    % Add the tiles and lables
    title('After Interpolating Previously Removed Channels (Magenta = Interpolated)')
    xlabel('Sample Number'); 
    ylabel('Amplitude (stacked)');
    
    % Adds channel label information (very cool)
    yticks(channel_offset);
    yticklabels(data_int.label);                            
    set(gca, 'FontSize', 8);
    
    axis ij; grid on; hold off;

    % If plots are to be saved then save them
    if strcmp(saveplots, 'yes')
        cfg_sp = [];
        cfg_sp.fig = fig;
        cfg_sp.plotname = 'intpfullchannels';
        cfg_sp.main = main;
        cfg_sp.skip = skip;
        cfg_sp.plotfolder = plotfolder;
        savehandlefig(cfg_sp)
    end

end


% if log is needed generate this output
if strcmp(log, 'yes')
    % Prepare function name and what it does
    step_name = 'intrpchans';
    fun_name = 'ft_channelinterpolate';

    % Prepare the stats structure
    stats = [];
    stats.initchannum = numel(data.label);
    stats.intpchannum = numel(badchannel);
    stats.intpchanlab = badchannel';
    stats.endingchannum = numel(data_int.label);
    stats.successful = 'yes';

    % Generate the log for this function
    data_int = ft_logstep(data_int, step_name, fun_name, cfg_org, stats);

    % Update that the log was recorded
    fprintf('ft_channelinterpolate log recorded\n');

end


end