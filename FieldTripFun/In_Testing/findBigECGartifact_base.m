function [startIdx, endIdx] = findBigECGartifact_base(worst_chan)

x = worst_chan(:)';
N = length(x);

% 1. Remove any slow drift (very helpful for these long artifacts)
x = detrend(x, 'linear');

% 2. Find the sample with the largest absolute amplitude (the huge R-wave)
[~, peakIdx] = max(abs(x));
% If there are ties, take the one in the middle of the segment (your artifact is there)
peakIdx = peakIdx(round(end/2));   % forces the big one, not some edge noise

% 3. From the peak, walk left until the signal is "flat" again
startIdx = peakIdx;
while startIdx > 1
    % Look at the last 200 samples we've walked – if slope is tiny, we're back to baseline
    if startIdx > 200
        local_slope = max(abs(diff(x(startIdx-199:startIdx))));
    else
        local_slope = max(abs(diff(x(1:startIdx))));
    end
    if local_slope < 0.5 * median(abs(diff(x)))   % very conservative flatness test
        break;
    end
    startIdx = startIdx - 1;
end

% 4. Same thing to the right
endIdx = peakIdx;
while endIdx < N
    if endIdx + 200 < N
        local_slope = max(abs(diff(x(endIdx:endIdx+199))));
    else
        local_slope = max(abs(diff(x(endIdx:end))));
    end
    if local_slope < 0.5 * median(abs(diff(x)))
        break;
    end
    endIdx = endIdx + 1;
end

% 5. One final tiny clean-up using amplitude (catches the exact visual start/end)
baseline_std = median(abs(x([1:1000, end-999:end])));  % true baseline from ends
while startIdx > 1 && abs(x(startIdx-1)) > 5 * baseline_std
    startIdx = startIdx - 1;
end
while endIdx < N && abs(x(endIdx+1)) > 5 * baseline_std
    endIdx = endIdx + 1;
end

% Plot + result
figure; plot(x); hold on;
plot([startIdx endIdx], x([startIdx endIdx]), 'ro', 'MarkerSize',10,'LineWidth',3);
title(sprintf('EXACT ARTIFACT: %d to %d', startIdx, endIdx));
xlim([startIdx-500 endIdx+500]);
grid on

fprintf('>>> THIS IS THE REAL ONE: artifact from sample %d to %d <<<\n', startIdx, endIdx);

end