function data = ft_addsweat(cfg, data)
%FT_ADDSWEAT add realistic multi-peak sweat artifacts with per-channel polarity
%
% cfg.sweat.duration     = [min max];   % seconds (default [3 5])
% cfg.sweat.amplitude    = scalar;      % µV (default 300)
% cfg.sweat.proportion   = scalar;      % fraction of total recording (default 0.3)
% cfg.sweat.coverage     = scalar;      % fraction of channels affected (default 0.9)
% cfg.sweat.smoothness   = scalar;      % 0-1, higher = rounder bumps (default 0.85)
% cfg.sweat.npeaks       = [min max];   % peaks per artifact region (default [2 3])
%
% example:
%   cfg = struct(); cfg.sweat.duration = [1 3.5]; cfg.sweat.amplitude = 800;
%   cfg.sweat.proportion = 0.3; cfg.sweat.coverage = 0.9;
%   cfg.sweat.smoothness = 0.99; cfg.sweat.npeaks = [1 2];
%   data = ft_addsweat(cfg, data);

cfg = ft_checkconfig(cfg, 'required', {'sweat'});
s   = cfg.sweat;

s.duration     = ft_getopt(s, 'duration',   [3 5]);
s.amplitude    = ft_getopt(s, 'amplitude',  300);
s.proportion   = ft_getopt(s, 'proportion', 0.3);
s.coverage     = ft_getopt(s, 'coverage',   0.9);
s.smoothness   = ft_getopt(s, 'smoothness', 0.85);
s.npeaks       = ft_getopt(s, 'npeaks',     [2 3]);

data = ft_checkconfig(data, 'required', {'label','trial','time','fsample'});

fsample = data.fsample;
nTrial  = numel(data.trial);
nChan   = numel(data.label);

trialLen = cellfun(@(x) size(x,2), data.trial);
totSmp   = sum(trialLen);
cumSmp   = [0 cumsum(trialLen)];
concat   = zeros(nChan, totSmp);
for tr = 1:nTrial
    idx = cumSmp(tr)+1 : cumSmp(tr+1);
    concat(:,idx) = data.trial{tr};
end

nAff   = round(nChan * s.coverage);
affIdx = randsample(nChan, nAff, false);
pol    = 2*(rand(1,nAff) > 0.5) - 1;

minSmp = max(round(s.duration(1)*fsample), round(1.5*fsample));
maxSmp = round(s.duration(2)*fsample);
needSmp = round(totSmp * s.proportion);

regStart = []; regEnd = []; covered = 0;
while covered < needSmp && numel(regStart) < 100
    durSmp = randi([minSmp, min(maxSmp, totSmp)]);
    maxSt  = totSmp - durSmp + 1;
    if maxSt < 1, break; end
    st = randi(maxSt); en = st + durSmp - 1;
    if ~isempty(regStart) && any(st <= regEnd & en >= regStart), continue; end
    regStart(end+1) = st; regEnd(end+1) = en;
    covered = covered + durSmp;
end

avgLen = mean([minSmp maxSmp]);
Nbase  = max(2000, round(avgLen));
tBase  = linspace(0,1,Nbase)';

nPeaks = randi(s.npeaks);
peakLoc = sort(rand(1,nPeaks))*0.8 + 0.1;

template = zeros(Nbase,1);
width = 0.25 + 0.35*s.smoothness;

for p = peakLoc
    dist = abs(tBase - p);
    arg  = pi * dist / width;
    bump = (arg < pi) .* (0.5*(1 + cos(arg)));
    template = template + bump;
end

template(1)   = 0;
template(end) = 0;

midIdx = round(0.05*Nbase) : round(0.95*Nbase);
template = template / max(template(midIdx));

edge = round(0.08*Nbase);
win  = ones(Nbase,1);
win(1:edge)               = linspace(0,1,edge)';
win(end-edge+1:end)       = linspace(1,0,edge)';
template = template .* win;
template = max(template,0);

for r = 1:numel(regStart)
    st  = regStart(r); en = regEnd(r); len = en-st+1;
    tReg = linspace(0,1,len);
    sig  = interp1(tBase, template, tReg, 'spline') * s.amplitude;
    sig(1) = 0; sig(end) = 0;
    
    for k = 1:nAff
        ch = affIdx(k);
        concat(ch, st:en) = concat(ch, st:en) + pol(k) * sig;
    end
end

for tr = 1:nTrial
    idx = cumSmp(tr)+1 : cumSmp(tr+1);
    data.trial{tr} = concat(:,idx);
end

fprintf('ft_addsweat: %d regions, %d/%d channels (random polarity)\n', ...
        numel(regStart), nAff, nChan);

end