function ft_developeegreport(cfg)
%FT_DEVELOPEEGREPORT  Generate a 2-column HTML QC report (FieldTrip style)
%
%   ft_developeegreport(cfg)
%
%   cfg fields (all optional, defaults shown):
%     cfg.pngfolder   = <folder with *.png files>      (required)
%     cfg.outputdir   = <folder for the HTML file>    (default: same as pngfolder)
%     cfg.htmlname    = <custom HTML filename>        (default: <foldername>_QC_report.html)
%     cfg.imgwidth    = 600;      % width of images in px
%     cfg.imgheight   = [];       % height (optional, keeps aspect ratio)
%     cfg.title       = 'EEG QC Report';
%     cfg.descriptions = struct();% struct with fieldnames = imagename (dots -> underscores)
%     cfg.header_at   = [];       % vector of image indices where a header starts
%     cfg.header_text = {};       % cell array of header strings (same length as header_at)
%
%   Example
%     cfg = struct();
%     cfg.pngfolder = '/tmp/eeg_qc_pngs';
%     cfg.outputdir = '/data/eeg_study/reports';
%     cfg.htmlname  = 'sub-01_QC.html';
%     cfg.imgwidth  = 800;
%     cfg.title     = 'EEG Preprocessing QC';
%     cfg.header_at = [1 4];
%     cfg.header_text = {'Raw data','Filtered data'};
%     ft_developeegreport(cfg);
%
%   The function opens the generated HTML in the default browser.

%% ---------------------------------------------------------------------%
% 1. DEFAULTS & VALIDATION
% ---------------------------------------------------------------------%
if ~isfield(cfg,'pngfolder') || isempty(cfg.pngfolder)
    error('cfg.pngfolder must be supplied.');
end
if ~isfolder(cfg.pngfolder)
    error('PNG folder not found: %s', cfg.pngfolder);
end

cfg.outputdir = ft_getopt(cfg, 'outputdir', cfg.pngfolder);
if ~isfolder(cfg.outputdir), mkdir(cfg.outputdir); end

cfg.htmlname   = ft_getopt(cfg, 'htmlname', []);
cfg.imgwidth   = ft_getopt(cfg, 'imgwidth', 600);
cfg.imgheight  = ft_getopt(cfg, 'imgheight', []);
cfg.title      = ft_getopt(cfg, 'title', 'EEG QC Report');
cfg.descriptions = ft_getopt(cfg, 'descriptions', struct());
cfg.header_at  = ft_getopt(cfg, 'header_at', []);
cfg.header_text= ft_getopt(cfg, 'header_text', {});

% ---------------------------------------------------------------------%
% 2. GET PNG FILES (sorted alphabetically)
% ---------------------------------------------------------------------%
pngFiles = dir(fullfile(cfg.pngfolder, '*.png'));
if isempty(pngFiles)
    error('No .png files found in %s', cfg.pngfolder);
end
[~, idx] = sort({pngFiles.name});
pngFiles = pngFiles(idx);

% ---------------------------------------------------------------------%
% 3. DETERMINE FINAL HTML PATH
% ---------------------------------------------------------------------%
[~, folderName] = fileparts(cfg.pngfolder);
if isempty(cfg.htmlname)
    htmlFile = fullfile(cfg.outputdir, [folderName '_QC_report.html']);
else
    htmlFile = fullfile(cfg.outputdir, cfg.htmlname);
end

% ---------------------------------------------------------------------%
% 4. OPEN FILE FOR WRITING
% ---------------------------------------------------------------------%
fid = fopen(htmlFile, 'w');
if fid == -1, error('Cannot write HTML file: %s', htmlFile); end

% ---------------------------------------------------------------------%
% 5. HTML HEAD
% ---------------------------------------------------------------------%
fprintf(fid, '<!DOCTYPE html>\n<html><head>\n');
fprintf(fid, '<meta charset="utf-8">\n');
fprintf(fid, '<title>%s: %s</title>\n', cfg.title, folderName);
fprintf(fid, '<style>\n');
fprintf(fid, '  body {font-family:Arial; margin:40px; line-height:1.6;}\n');
fprintf(fid, '  h1 {text-align:center; color:#2c3e50;}\n');
fprintf(fid, '  h2 {color:#2980b9; border-bottom:2px solid #3498db; padding-bottom:5px; margin-top:40px;}\n');
fprintf(fid, '  .gallery {display:flex; flex-wrap:wrap; gap:20px; justify-content:center; margin:30px 0;}\n');
fprintf(fid, '  .imgblock {flex:1 1 calc(50%% - 20px); max-width:calc(50%% - 20px); text-align:center;}\n');
fprintf(fid, '  img {max-width:100%%; ');
if ~isempty(cfg.imgheight)
    fprintf(fid, 'width:%dpx; height:%dpx; ', cfg.imgwidth, cfg.imgheight);
else
    fprintf(fid, 'width:%dpx; ', cfg.imgwidth);
end
fprintf(fid, 'border:1px solid #ccc; display:block; margin:0 auto 10px; border-radius:4px;}\n');
fprintf(fid, '  .cap {font-style:italic; color:#555; margin-bottom:5px;}\n');
fprintf(fid, '  .desc {margin:10px 0; padding:10px; background:#f9f9f9; border-left:4px solid #3498db; font-size:14px; border-radius:0 4px 4px 0;}\n');
fprintf(fid, '</style>\n</head><body>\n');
fprintf(fid, '<h1>%s: %s</h1>\n', cfg.title, folderName);
fprintf(fid, '<p><em>Generated: %s</em></p><hr>\n', datestr(now));

% ---------------------------------------------------------------------%
% 6. WRITE IMAGES + OPTIONAL HEADERS
% ---------------------------------------------------------------------%
inGallery = false;
for i = 1:length(pngFiles)
    imgName = pngFiles(i).name;
    fieldName = strrep(imgName, '.', '_');   % for description lookup

    % ---- HEADER BEFORE THIS IMAGE? ----
    if ~isempty(cfg.header_at) && any(i == cfg.header_at)
        hdrIdx = find(i == cfg.header_at, 1);
        headerTxt = cfg.header_text{hdrIdx};

        if inGallery
            fprintf(fid, ' </div>\n');   % close previous gallery
            inGallery = false;
        end
        fprintf(fid, '<h2>%s</h2>\n', headerTxt);
    end

    % ---- OPEN GALLERY IF NEEDED ----
    if ~inGallery
        fprintf(fid, ' <div class="gallery">\n');
        inGallery = true;
    end

    % ---- IMAGE BLOCK ----
    fprintf(fid, '  <div class="imgblock">\n');

    % read & Base64-encode
    imgPath = fullfile(cfg.pngfolder, imgName);
    imgData = fileread(imgPath);                     % binary
    imgB64  = matlab.net.base64encode(imgData);
    fprintf(fid, '   <img src="data:image/png;base64,%s" alt="%s">\n', imgB64, imgName);
    fprintf(fid, '   <div class="cap">Figure %d: %s</div>\n', i, imgName);

    % optional description
    if isfield(cfg.descriptions, fieldName)
        fprintf(fid, '   <div class="desc">%s</div>\n', cfg.descriptions.(fieldName));
    end

    fprintf(fid, '  </div>\n');
end

% close final gallery
if inGallery
    fprintf(fid, ' </div>\n');
end

% ---------------------------------------------------------------------%
% 7. HTML FOOTER
% ---------------------------------------------------------------------%
fprintf(fid, '</body></html>\n');
fclose(fid);

% ---------------------------------------------------------------------%
% 8. OPEN IN BROWSER
% ---------------------------------------------------------------------%
fprintf('HTML report written to:\n   %s\n', htmlFile);
%web(htmlFile);
end

% ---------------------------------------------------------------------%
% Helper (FieldTrip-style option getter)
% ---------------------------------------------------------------------%
function val = ft_getopt(cfg, field, default)
if isfield(cfg, field) && ~isempty(cfg.(field))
    val = cfg.(field);
else
    val = default;
end
end