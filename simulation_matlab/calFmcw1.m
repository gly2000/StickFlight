%% ================================================
%% Yi-Chao Chen
%% @INPUT(y         ): audio data
%% @INPUT(stdIdx    ): index of the start of the first chirp
%% @INPUT(y0        ): FMCW chirp
%% @INPUT(Ke        ): FMCW sequence length (sample)
%% @INPUT(K         ): FMCW chirp length (sample)
%% @INPUT(Fs        ): Sampling rate
%% @INPUT(fmin      ): Minimal FMCW chirp frequency
%% @INPUT(fmax      ): Maximal FMCW chirp frequency
%% @INPUT(vs        ): Sound speed
%% @INPUT(enablePlot): if to plot figures
%% ================================================
function [estDists, estTime, estDistsCancl, estTimeCancl] = calFmcw1( ...
        y, stdIdx, y0, Ke, K, Fs, fmin, fmax, vs, enablePlot)
    
    bw = fmax - fmin;
    chirpLenS = K / Fs;

    K1 = Ke - K;
    y0ext = [y0, zeros(1, K1)];

    w = 0.5 - 0.5*cos(2*pi/K*(0:K-1));

    maxTrackDist = 2000 * 2;
    maxTrackFreq = floor(min(Fs/2, FmcwDist2Freq(maxTrackDist, chirpLenS, bw, vs)));
    minTrackDist = 40 * 2;
    minTrackFreq = floor(max(1, FmcwDist2Freq(minTrackDist, chirpLenS, bw, vs)));
    searchRange  = [minTrackFreq:maxTrackFreq];
    searchRangeCancl = [1:maxTrackFreq];

    [len, nMic] = size(y);

    estDists = {};
    estTime  = {}; 
    estDistsCancl = {};
    estTimeCancl  = {}; 

    for mi = 1:nMic
        pidx = stdIdx;
        prev_r = -1;
        resync_cnt = 0;
        est_dist = [];
        est_time = [];
        est_dist_cancl = [];
        est_time_cancl = [];
        while 1
            if pidx + K > len
                break;
            end

            %% check if need to resync
            r = abs(sum(y([1:K]+pidx-1, mi) .* y0'));
            if(r < prev_r / 2)
                resync_cnt = resync_cnt + 1;

                [tmp_idx,~] = syncFMCWSymbol(y(pidx:end, :), y0ext, Ke, Fs, fmin, fmax, 0);
                pidx = tmp_idx + pidx - 1;
                continue;
            end
            prev_r = r;

            %% mix
            s = y([1:K]+pidx-1, mi)';
            s = s .* w;
            % s = fftFilter(s, Fs, fmin, fmax, 100);
            ym = s .* y0;
            Ym = fft(ym, Fs);
            Ym = abs(Ym(1:Fs/2));

            %% find peak
            [~,idx] = max(Ym(searchRange));
            est_dist = [est_dist FmcwFreq2Dist(idx+searchRange(1)-1, chirpLenS, bw, vs)];
            est_time = [est_time pidx / Fs];

            %% cancel
            if length(est_dist) > 1
                Ymd = abs(Ym - prevYm);
                %% find peak
                [mag,idx2] = max(Ymd(searchRangeCancl));
                est_dist_cancl = [est_dist_cancl FmcwFreq2Dist(idx2+searchRangeCancl(1)-1, chirpLenS, bw, vs)];
                est_time_cancl = [est_time_cancl pidx / Fs];

                if mag < 10
                    est_dist_cancl(end) = est_dist(end);
                end
            end
            prevYm = Ym;

            if(enablePlot)
                figure(enablePlot); clf; 
                subplot(4,1,1); hold on;
                plot(Ym, '-bo');
                plot([minTrackFreq minTrackFreq], [0, max(Ym)], '-r');
                plot([maxTrackFreq maxTrackFreq], [0, max(Ym)], '-r');
                title(sprintf('pidx=%d', pidx))
                subplot(4,1,2); hold on;
                plot(FmcwFreq2Dist(searchRange, chirpLenS, bw, vs), Ym(searchRange), '-bo');
                plot(est_dist(end), Ym(idx+searchRange(1)-1), 'ro');
                subplot(4,1,3); hold on;
                if length(est_dist) > 1
                    plot(FmcwFreq2Dist(searchRange, chirpLenS, bw, vs), Ymd(searchRange), '-bo');
                    plot(FmcwFreq2Dist(idx2+searchRangeCancl(1)-1, chirpLenS, bw, vs), Ymd(idx2+searchRangeCancl(1)-1), 'ro');
                end
                subplot(4,1,4); hold on;
                plot(est_time, est_dist, '-bo');
                plot(est_time_cancl, est_dist_cancl, '-rx');
                pause(0.01);
            end

            pidx = pidx + Ke;
        end

        estDists{mi} = est_dist;
        estTime{mi}  = est_time;
        estDistsCancl{mi} = est_dist_cancl;
        estTimeCancl{mi}  = est_time_cancl;

        fprintf(' resync cnt = %d\n', resync_cnt);
    end

    

end
