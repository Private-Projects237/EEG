function ft_developeegreport(folderPath, cfg)
% FT_DEVELOPEEGREPORT  Generate 2-column HTML QC report with headers at specific image indices
%
%   cfg.header_at   = [3, 7, 12];        % insert header BEFORE these image numbers
%   cfg.header_text = {'Raw', 'Filter', 'ICA'};

%% --- DEFAULTS ---------------------------------------------------------
if nargin < 2 || isempty(cfg), cfg = struct(); end
if ~isfield(cfg,'imgwidth'),     cfg.imgwidth  = 600; end
if ~isfield(cfg,'imgheight'),    cfg.imgheight = [];  end
if ~isfield(cfg,'title'),        cfg.title     = 'EEG QC Report'; end
if ~isfield(cfg,'descriptions'), cfg.descriptions = struct(); end
if ~isfield(cfg,'header_at'),    cfg.header_at = []; end
if ~isfield(cfg,'header_text'),  cfg.header_text = {}; end

%% --- VALIDATE ---------------------------------------------------------
if ~isfolder(folderPath), error('Folder not found: %s',folderPath); end

%% --- GET PNGs (sorted alphabetically) -------------------------------
pngFiles = dir(fullfile(folderPath,'*.png'));
if isempty(pngFiles), error('No .png files in folder.'); end
[~,idx] = sort({pngFiles.name});
pngFiles = pngFiles(idx);

%% --- HTML FILE --------------------------------------------------------
[~,folderName] = fileparts(folderPath);
htmlFile = fullfile(folderPath, [folderName '_QC_report.html']);
fid = fopen(htmlFile,'w');
if fid == -1, error('Cannot write HTML file.'); end

%% --- HTML HEAD --------------------------------------------------------
fprintf(fid,'<!DOCTYPE html>\n<html><head>\n');
fprintf(fid,'<meta charset="utf-8">\n<title>%s: %s</title>\n',cfg.title,folderName);
fprintf(fid,'<style>\n');
fprintf(fid,'  body {font-family:Arial; margin:40px; line-height:1.6;}\n');
fprintf(fid,'  h1 {text-align:center; color:#2c3e50;}\n');
fprintf(fid,'  h2 {color:#2980b9; border-bottom:2px solid #3498db; padding-bottom:5px; margin-top:40px;}\n');
fprintf(fid,'  .gallery {display:flex; flex-wrap:wrap; gap:20px; justify-content:center; margin:30px 0;}\n');
fprintf(fid,'  .imgblock {flex:1 1 calc(50%% - 20px); max-width:calc(50%% - 20px); text-align:center;}\n');
fprintf(fid,'  img {max-width:100%%; ');
if ~isempty(cfg.imgheight)
    fprintf(fid,'width:%dpx; height:%dpx; ',cfg.imgwidth,cfg.imgheight);
else
    fprintf(fid,'width:%dpx; ',cfg.imgwidth);
end
fprintf(fid,'border:1px solid #ccc; display:block; margin:0 auto 10px; border-radius:4px;}\n');
fprintf(fid,'  .cap {font-style:italic; color:#555; margin-bottom:5px;}\n');
fprintf(fid,'  .desc {margin:10px 0; padding:10px; background:#f9f9f9; border-left:4px solid #3498db; font-size:14px; border-radius:0 4px 4px 0;}\n');
fprintf(fid,'</style>\n</head><body>\n');

fprintf(fid,'<h1>%s: %s</h1>\n',cfg.title,folderName);
fprintf(fid,'<p><em>Generated: %s</em></p><hr>\n',datestr(now));

%% --- WRITE IMAGES + HEADERS -------------------------------------------
inGallery = false;

for i = 1:length(pngFiles)
    imgName   = pngFiles(i).name;
    fieldName = strrep(imgName,'.','_');   % for descriptions only

    % --- INSERT HEADER BEFORE SPECIFIC IMAGE INDEX ---
    if ~isempty(cfg.header_at) && any(i == cfg.header_at)
        idx = find(i == cfg.header_at, 1);
        headerText = cfg.header_text{idx};

        % Close previous gallery
        if inGallery
            fprintf(fid,'  </div>\n');
            inGallery = false;
        end

        % Print header
        fprintf(fid,'<h2>%s</h2>\n', headerText);
    end

    % Open new gallery if needed
    if ~inGallery
        fprintf(fid,'  <div class="gallery">\n');
        inGallery = true;
    end

    % --- IMAGE BLOCK ---
    fprintf(fid,'    <div class="imgblock">\n');
    fprintf(fid,'      <img src="%s" alt="%s">\n',imgName,imgName);
    fprintf(fid,'      <div class="cap">Figure %d: %s</div>\n',i,imgName);

    if isfield(cfg.descriptions, fieldName)
        fprintf(fid,'      <div class="desc">%s</div>\n',cfg.descriptions.(fieldName));
    end
    fprintf(fid,'    </div>\n');
end

% Close final gallery
if inGallery
    fprintf(fid,'  </div>\n');
end

%% --- HTML FOOTER ------------------------------------------------------
fprintf(fid,'</body></html>\n');
fclose(fid);

%% --- OPEN IN BROWSER --------------------------------------------------
web(htmlFile);
end