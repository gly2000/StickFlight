%% ================================================
%% Yi-Chao Chen
%% @INPUT(y         ): audio data
%% @INPUT(stdIdx    ): index of the start of the first chirp
%% @INPUT(y0        ): FMCW sequence (including guard interval)
%% @INPUT(Ke        ): FMCW sequence length (sample)
%% @INPUT(K         ): FMCW chirp length (sample)
%% @INPUT(Fs        ): Sampling rate
%% @INPUT(fmin      ): Minimal FMCW chirp frequency
%% @INPUT(fmax      ): Maximal FMCW chirp frequency
%% @INPUT(vs        ): Sound speed
%% @INPUT(enablePlot): if to plot figures
%% ================================================
function [estDists, estTime] = calToF( ...
        y, stdIdx, y0, Ke, K, Fs, fmin, fmax, vs, enablePlot)
    
    bw = fmax - fmin;
    chirpLenS = K / Fs;

    [len, nMic] = size(y);
    nChirp = floor((len - stdIdx) / Ke) - 1;

    minTrackDist = 50 * 2;
    minTrackTime = floor(minTrackDist / vs * Fs);
    maxTrackDist = 500 * 2;
    maxTrackTime = ceil(maxTrackDist / vs * Fs);
    fprintf('  calToF: min/max sample = %d/%d (chirp len = %d)\n', minTrackTime, maxTrackTime, K);

    estDists = {};
    estTime  = {};
    for mi = 1:nMic
        resync_cnt    = 0;
        prev_corr     = 0;
        select_peaks  = [];
        est_time      = [];
        ci = 0;
        while 1
            if ci >= nChirp
                break;
            end
            ci = ci + 1;

            std_idx = stdIdx + (ci-1) * Ke;
            corrs   = zeros(1, maxTrackTime);
            for ti = 1:maxTrackTime
                yf = y([0:Ke-1] + std_idx+ti-1, mi);
                corrs(ti) = sum(yf' .* y0);
            end
            corrs = abs(corrs);

            if prev_corr > 0 & corrs(1) < prev_corr / 2
                %% need to resync
                resync_cnt = resync_cnt + 1;

                [stdIdx, tmp_corr] = syncFMCWSymbol(y(std_idx:end, :), y0, Ke, Fs, fmin, fmax, 0);

                stdIdx = stdIdx + std_idx - 1;
                nChirp = floor((len - stdIdx) / Ke) - 1;
                ci = 0;
                continue;
            end

            prev_corr = corrs(1);

            thrd = max(corrs(floor(minTrackTime/2):minTrackTime));
            idx = find(corrs > thrd);
            peak_idx = -1;
            for ii = 1:length(idx)
                if(idx(ii) > 1 & idx(ii) > minTrackTime)
                    minidx = max(1, idx(ii)-5);
                    maxidx = min(maxTrackTime, idx(ii)+5);
                    is_peak = 1;
                    for ti = minidx:maxidx
                        if(corrs(ti) > corrs(idx(ii)))
                            is_peak = 0;
                            break;
                        end
                    end

                    if is_peak == 1
                        peak_idx = idx(ii);
                        break;
                    end
                    % if(corrs(idx(ii)-1) < corrs(idx(ii)) & corrs(idx(ii)+1) < corrs(idx(ii)))
                    %     peak_idx = idx(ii);
                    %     break;
                    % end
                end
            end

            if(peak_idx <= 0 & length(select_peaks) > 0) 
                prev_peak_idx = select_peaks(end);
                search_min = max(minTrackTime, floor(prev_peak_idx - 100 / vs * Fs));
                [~,peak_idx] = max(corrs(search_min:maxTrackTime));
                peak_idx = peak_idx(1) + search_min - 1;
            end

            select_peaks = [select_peaks peak_idx];
            est_time     = [est_time std_idx / Fs];

            if(enablePlot > 0)
                figure(enablePlot); clf; 
                subplot(2,1,1); hold on;
                plot(corrs, '-b.');
                plot(peak_idx, corrs(peak_idx), 'ro');
                title(sprintf('chirp%d, std_idx=%d, resync_cnt=%d', ci, std_idx, resync_cnt));
                subplot(2,1,2); hold on;
                plot(est_time, select_peaks / Fs * vs, '-bo');
                pause(0.01);
            end

        end

        fprintf(' resync cnt = %d\n', resync_cnt);

        est_dists = select_peaks / Fs * vs;
        if(enablePlot > 0)
            figure(enablePlot); clf; hold on;
            plot(est_time, select_peaks / Fs * vs, '-bo');
            pause
        end

        estDists{mi} = est_dists;
        estTime{mi}  = est_time;
    end

    
    % L    = 35*Ke;  %% searching range
    % corr = zeros(1,L);
    % for mi = 1:size(y,2)
        
    %     yf = y([1:L+Ke] + stdIdx - 1, mi);
        
    %     for i = 1:L
    %         corr(i) = corr(i) + y0 * yf((0:Ke-1)+i);
    %     end

    % end

    % if (enablePlot >= 1)
    %     fh = figure(enablePlot); clf; hold on;
    %     plot(abs(corr), '-b.');
    %     plot([0:34]*Ke+1, abs(corr([0:34]*Ke+1)), 'ro');
    %     pause();
    % end

end
