%% ================================================
%% Yi-Chao Chen
%% ================================================
function [maxIndex, corr] = syncFMCWSymbol( ...
        y, ...             %% audio data
        y0, ...            %% tx FMCW chirp from left speaker
        K, ...             %% FMCW chirp length (sample) 
        Fs, ...            %% Audio Sampling Rate
        fmin, ...          %% Minimal FMCW chirp frequency
        fmax, ...          %% Maximal FMCW chirp frequency
        enablePlot ...     %% if to plot figures
    )

    L    = 4*K;  %% searching range
    corr = zeros(1,L);
    for mi = 1:size(y,2)
        
        yf = y(1:L+K, mi);
        
        for i = 1:L
            corr(i) = corr(i) + y0 * yf((0:K-1)+i);
        end

    end

    [~,maxIndex] = max(abs(corr));
    if (enablePlot >= 1)
        fh = figure(enablePlot); clf; hold on;
        plot(abs(corr), '-b.');
        plot(maxIndex, abs(corr(maxIndex)), 'ro');
        pause();
    end
    
    while(maxIndex + K < 4*K) 
        maxIndex = maxIndex + K;
    end

end
