function ft_png2html(cfg)
%FT_PNG2HTML Create a standalone HTML file with embedded PNG images from a directory
%
%   ft_png2html(cfg)
%
% This function scans a directory for PNG files, embeds them as Base64 data URIs
% into a simple HTML gallery, and writes the result to an output file.
% The resulting HTML is fully self-contained: it will display the images even
% if the original PNG files are deleted or moved.
%
% Input:
%   cfg           - configuration structure with fields:
%     .inputdir   - string, path to directory containing PNG files (required)
%     .outputdir  - string, path to directory to save the .html 
%     .filename   - name of the .html file (001_RAW.html)
%     .title      - string, title of the HTML page (default: 'PNG Image Gallery')
%     .columns    - integer, number of columns in the grid (default: 3)
%     .imgwidth   - string or number, width of each image in CSS (default: '90%')
%     .cleanup    - 'yes'/'no' deletes all the PNGs in the folder
%
% Example:
%   cfg = [];
%   cfg.inputdir = '/path/to/your/pngs';
%   cfg.outputdir = '/path/to/html';
%   cfg.filename = 'my_gallery.html';
%   cfg.title = 'My Analysis Figures';
%   cfg.columns = 4;
%   ft_png2html(cfg);
%
% The HTML uses a responsive CSS grid for nice display on desktop/mobile.
%
% See also: DIR, FOPEN, MATLAB.NET.BASE64ENCODE

% defaults and checking
if nargin == 0
    error('cfg input is required');
end

if ~isfield(cfg, 'inputdir') || isempty(cfg.inputdir)
    error('cfg.inputdir must be specified');
end

if ~isfolder(cfg.inputdir)
    error('cfg.inputdir "%s" is not a valid directory', cfg.inputdir);
end

if ~isfield(cfg, 'outputdir') || isempty(cfg.outputdir)
    error('cfg.outputdir "%s" is not a valid directory', cfg.inputdir);
end

if ~isfield(cfg, 'filename') || isempty(cfg.filename)
    error('cfg.filename "%s" is required- must specify .html file name', cfg.inputdir);
end

if ~isfield(cfg, 'title')
    cfg.title = 'PNG Image Gallery';
end

if ~isfield(cfg, 'columns')
    cfg.columns = 3;
end

if ~isfield(cfg, 'imgwidth')
    cfg.imgwidth = '90%';  % percentage for responsive layout
end

if ~isfield(cfg, 'cleanup')
    cfg.cleanup = 'no';  % percentage for responsive layout
end

% Some cheesing to make the code work
cfg.outputfile = fullfile(cfg.outputdir, cfg.filename);

% find PNG files
files = dir(fullfile(cfg.inputdir, '*.png'));
if isempty(files)
    warning('No PNG files found in %s', cfg.inputdir);
    return;
end

[~, sortedNames] = sort({files.name});
files = files(sortedNames);  % alphabetical order

% start building HTML
html = {};
html{end+1} = '<!DOCTYPE html>';
html{end+1} = '<html lang="en">';
html{end+1} = '<head>';
html{end+1} = '    <meta charset="utf-8">';
html{end+1} = sprintf('    <title>%s</title>', cfg.title);
html{end+1} = '    <style>';
html{end+1} = '        body { font-family: Arial, sans-serif; margin: 40px; background: #f9f9f9; }';
html{end+1} = sprintf('        h1 { text-align: center; }');
html{end+1} = '        .gallery {';
html{end+1} = sprintf('            display: grid; grid-template-columns: repeat(%d, 1fr); gap: 20px;', cfg.columns);
html{end+1} = '            max-width: 1200px; margin: 0 auto;';
html{end+1} = '        }';
html{end+1} = '        .item { background: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); text-align: center; }';
html{end+1} = sprintf('        .item img { width: %s; height: auto; border-radius: 4px; }', cfg.imgwidth);
html{end+1} = '        .caption { margin-top: 10px; font-size: 0.9em; color: #555; }';
html{end+1} = '    </style>';
html{end+1} = '</head>';
html{end+1} = '<body>';
html{end+1} = sprintf('    <h1>%s</h1>', cfg.title);
html{end+1} = '    <div class="gallery">';

% embed each image
for k = 1:numel(files)
    filename = fullfile(files(k).folder, files(k).name);
    
    % read raw bytes
    fid = fopen(filename, 'rb');
    if fid == -1
        warning('Could not open %s', filename);
        continue;
    end
    raw = fread(fid, '*uint8');
    fclose(fid);
    
    % base64 encode
    b64 = matlab.net.base64encode(raw);
    
    % add to gallery
    html{end+1} = '        <div class="item">';
    html{end+1} = sprintf('            <img src="data:image/png;base64,%s" alt="%s">', b64, files(k).name);
    html{end+1} = sprintf('            <div class="caption">%s</div>', files(k).name);
    html{end+1} = '        </div>';
end

% finish HTML
html{end+1} = '    </div>';
html{end+1} = '</body>';
html{end+1} = '</html>';

% write file
fid = fopen(cfg.outputfile, 'w', 'n', 'UTF-8');
if fid == -1
    error('Could not open output file %s for writing', cfg.outputfile);
end
fprintf(fid, '%s\n', html{:});
fclose(fid);

% Clean up if specified
if strcmp(cfg.cleanup, 'yes')
    fprintf('Cleaning up: deleting %d PNG file(s)...\n', numel(files));
    deleted = 0;
    for k = 1:numel(files)
        filename = fullfile(files(k).folder, files(k).name);
        try
            delete(filename);
            deleted = deleted + 1;
        catch ME
            warning('Failed to delete %s: %s', filename, ME.message);
        end
    end
    fprintf('Deleted %d PNG file(s).\n', deleted);
end

fprintf('HTML gallery written to: %s\n', cfg.outputfile);
fprintf('Contains %d embedded PNG images.\n', numel(files));

end