%% ================================================
%% Yi-Chao Chen @ SJTU
%% ================================================
function simFmcw2(seed)
    if nargin < 1, seed = 2; end
    addpath('functions');

    rng(seed);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Configuration
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    font_size  = 18;
    
    %% Audio Configuration
    Fs = 48000;     %% Audio Sampling Rate
    Ts = 1/Fs;
    vs = 343000;    %% Sound Speed in mm/s

    %% Options
    PLOT_SPECTRUM = 1;
    PLOT_PEAKS    = 1;
    HANNING_WIN   = 1;
    %% Cancellation Type:
    %%   NO  = no cancellation; 
    %%   CST = constant sacle
    %%   DYN = dynamically adjust scale; 
    CANCEL_TYPE   = 'DYN';
    ADD_NOISE     = 1;
    ADD_ENV_OBJ   = 1;
    ADD_MULTIPATH = 1;

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% FMCW: 
    %%   Parameters
    %%
    %%    /|      /|      /|      /|      /|      /|     F_fmcw + B
    %%   / |     / |     / |     / |     / |     / |   
    %%  /  |    /  |    /  |    /  |    /  |    /  |   
    %% /   |---/   |---/   |---/   |---/   |---/   |---  F_fmcw
    %%   K  K1  (Ke = K + K1)
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    chirp_len    = 0.04;
    seq_len      = 0.05;
    F_fmcw       = 11000;
    B            = 10000;
    %% one chirp signals
    K            = round(Fs * chirp_len);
    Ke           = round(Fs * seq_len);
    K1           = Ke - K;
    t            = (0 : K - 1) * Ts;
    FMCWChirp    = cos(2 * pi * (1/2 * t.^2 * B / chirp_len + F_fmcw * t) );
    FMCWChirpExt = [FMCWChirp, zeros(1, K1)];


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Simulation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    audioLenS   = 10;  %% seconds
    audioLen    = audioLenS * Fs;
    nChirps     = ceil(audioLen / Ke);
    audioLenS   = nChirps * seq_len;
    audioLen    = nChirps * Ke;
    y           = repmat(FMCWChirpExt, 1, nChirps)';
    

    %% =======================================
    %% Simulate the movement:
    %%   0-2s : no target
    %%   2-3s : target is stationary
    %%   3-10s: target is moving. In each second, target either moves or stays
    %% =======================================
    PERIOD_NO_TARGET = 2;
    PERIOD_STATIC    = 1;
    START_TRACK      = PERIOD_NO_TARGET + PERIOD_STATIC;

    initDist = 2000;  %% in mm
    prv_dist = initDist;
    speed    = 0;
    gtDist   = zeros(1, nChirps);
    gtTime   = [0:nChirps-1] * seq_len;
    for ci = 1:nChirps
        cur_time = (ci-1) * seq_len;
        new_dist = prv_dist;
        if cur_time < PERIOD_NO_TARGET, 
            %% no target, so no reflected signals
        else
            if cur_time < START_TRACK
                %% target is stationary
                new_dist = initDist;
            else
                prv_time = (ci-2) * seq_len;
                if floor(cur_time) - floor(prv_time) > 0
                    %% start of a second: either moves or stays
                    if rand(1) > 0.9
                        %% stay
                        speed = 0;
                    else
                        %% move: speed < 500 mm/s
                        speed = (rand(1)*2 - 1)*1000/2;
                    end
                end
                new_dist = prv_dist + speed * seq_len;
            end

            %% add reflected signals from target
            lag     = ceil(new_dist * 2 / vs * Fs);
            std_idx = (ci-1)*Ke + 1 + lag;
            end_idx = min(std_idx+Ke-1, nChirps*Ke);
            idx     = std_idx:end_idx;
            mag     = attenuation(new_dist*2);
            y(idx)  = y(idx) + mag*FMCWChirpExt(1:length(idx))';
            
            %% add multipath
            if ADD_MULTIPATH
                nMultipath = 4;
                for mi = 1:nMultipath
                    multi_dist = new_dist + rand(1)*5000;
                    lag     = ceil(multi_dist * 2 / vs * Fs);
                    std_idx = (ci-1)*Ke + 1 + lag;
                    end_idx = min(std_idx+Ke-1, nChirps*Ke);
                    idx     = std_idx:end_idx;
                    mag     = attenuation(multi_dist*2);
                    y(idx)  = y(idx) + mag*FMCWChirpExt(1:length(idx))';
                end
            end
 
            prv_dist = new_dist;
        end
        gtDist(ci) = new_dist;
    end

    figure(1); clf;
    plot(gtTime, gtDist, '-bo');
    xlabel('Time (s)');
    ylabel('Distance (mm)');
    title('Ground Truth Distance');
    pause(0.01)
    

    %% =======================================
    %% Simulate Static Objects in the Environments
    %% =======================================
    if ADD_ENV_OBJ
        nObj   = 5;
        objAtt = 0.5;
        objDists = rand(1, nObj) * 3000;

        for oi = 1:nObj
            lag = ceil(objDists(oi) * 2 / vs * Fs);
            mag = objAtt * attenuation(objDists(oi)*2);
            
            std_idx = lag+1;
            num = floor((length(y) - std_idx + 1) / Ke);
            end_idx = std_idx + num * Ke - 1;
            y(std_idx:end_idx,1) = y(std_idx:end_idx,1) + mag*repmat(FMCWChirpExt', num, 1);
            remain_len = length(y) - end_idx;
            y(end_idx+1:end) = y(end_idx+1:end) + mag*FMCWChirpExt(1:remain_len)';
        end
    end


    %% =======================================
    %% Simulate white noise
    %% =======================================
    if ADD_NOISE
        noise_power = -30;
        noise = wgn(audioLen, 1, noise_power);
        y2 = y + noise;
        figure(1); clf; hold on;
        plot([0:Ke-1]/Fs, y(1:Ke), '-b.');
        plot([0:Ke-1]/Fs, y2(1:Ke), ':r.');
        legend('w/o noise', 'w/ noise');
        xlabel('Time (s)');
        ylabel('Mag');
        title('Simulate White Noise');
        pause(0.01)

        y = y2;
    end
    
    y = y / max(y);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Distance Estimation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    maxTrackDist = max(gtDist) * 3;
    maxTrackFreq = floor(min(Fs/2, FmcwDist2Freq(maxTrackDist, chirp_len, B, vs)));
    minTrackDist = 300;
    minTrackFreq = floor(max(1, FmcwDist2Freq(minTrackDist, chirp_len, B, vs)));
    search_range = [minTrackFreq:maxTrackFreq];


    %% =========================================
    %% Sync by correlation
    [maxIndex, tmp_corr] = syncFMCWSymbol(y, FMCWChirpExt, Ke, Fs, F_fmcw, F_fmcw+B, 0);
    fprintf('  sync FMCW max index = %d\n', maxIndex);
    
    fh = figure(1); clf; 
    subplot(2,1,1); hold on;
    plot(y(1:10*Ke), '-b.');
    plot(maxIndex, y(maxIndex), 'ro');
    plot([maxIndex:maxIndex+K], y([maxIndex:maxIndex+K]), '-r');
    xlim([1, 5*Ke]);
    xlabel('Time');
    ylabel('Mag');
    title('Synchronization: Received Audio');
    subplot(2,1,2); hold on;
    plot(abs(tmp_corr), '-b.');
    plot(maxIndex, abs(tmp_corr(maxIndex)), 'ro');
    xlim([1, 5*Ke]);
    xlabel('Time');
    ylabel('Correlation');
    title('Synchronization: Correlation');
    pause(0.01)


    %% =========================================
    %% cancellation
    nCancel    = floor(1 / seq_len);
    tmp        = reshape(y(maxIndex+5*Ke:maxIndex+Ke*nCancel-1, 1), Ke, []);
    cancel_sig = mean(tmp, 2);


    %% ====================================
    %% Short-Time Fourier Transform
    if PLOT_SPECTRUM
        window    = floor(Fs/256);
        noverlap  = floor(window/4); % 75% overlap
        
        %% Spectrogram takes the STFT of the signal
        %% P matrix contains the power spectral density of each segment of the STFT
        [S,F,T,P] = spectrogram(y([maxIndex:maxIndex+10*Ke]), window, noverlap, Fs, Fs);
        
        fh = figure(2); clf;
        imagesc(T, F, 10*log10(P)); % frequency-time Plot of the signal
        colorbar;
        xlabel('Time (s)');
        ylabel('Power/Frequency (dB/Hz)');
        pause(0.01)
    end
    


    %% =========================================
    %% Detect the range based on FMCW
    startIndex = maxIndex - 1;
    nChirps    = floor((length(y) - startIndex) / Ke);  %% number of chirp to analyze
    
    fmcwTime = [0:nChirps-1] * seq_len + startIndex/Fs;
    fmcwPeak = zeros(nChirps, 1);
    fmcwSNR  = zeros(nChirps, 1);
    
    if HANNING_WIN
        w   = 0.5 - 0.5*cos(2*pi/K*(0:K-1)); %% Hanning Window
    else
        w   = ones(1, K);
    end
    
    cidx    = 1;
    while cidx <= nChirps
        s = y([0:K-1] + Ke*(cidx-1) + startIndex)';

        %% --------------------
        %% Cancellation
        %% --------------------
        if strcmpi(CANCEL_TYPE, 'NO')
            c = 0;
        elseif strcmpi(CANCEL_TYPE, 'CST')
            c = 1;
        elseif strcmpi(CANCEL_TYPE, 'DYN')
            c = linsolve(cancel_sig(1:K), s'); %% find the best scaling
        else
            error('wrong cancellation type');
        end

        s = s - c * cancel_sig(1:K)';


        %% --------------------
        %% Mix Signal
        %% --------------------
        sw = s .* w;
        sn = fftFilter(sw, Fs, F_fmcw, F_fmcw+B, 100); %% bandpass filter
        ym = sn .* FMCWChirp;
        Ym = fft(ym, Fs);
        Ym = Ym(1:Fs/2);
        ys = abs(Ym(search_range));

        
        %% --------------------
        %% Peak Selection: i) is max, ii) is peak (i.e., nearby samples are smaller)
        %% --------------------
        prev_peak = 1;
        if(cidx > 1)
            prev_peak = fmcwPeak(cidx-1);
        end
        
        [~, ys_idx] = sort(ys, 'descend');
        fmcwPeak(cidx) = prev_peak;
        peak_range = 2;
        for yi = 1:length(ys_idx)
            idx = ys_idx(yi);

            %% too close to start or end of the chirp
            if(idx <= peak_range | idx >= length(ys_idx)-peak_range)
                continue;
            end

            %% is a peak
            if(ys(idx) >= ys(idx-peak_range:idx+peak_range)) 
                fmcwPeak(cidx) = idx;
                break;
            end
        end
        
        fmcwSNR(cidx)  = ys(fmcwPeak(cidx)) / mean(ys);
        fmcwPeak(cidx) = fmcwPeak(cidx) + search_range(1) - 1;



        if PLOT_PEAKS
            tmpys = abs(Ym);
            fh = figure(12); clf;
            subplot(3,1,1); hold on;
            plot(tmpys, '-b.');
            plot(fmcwPeak(cidx), tmpys(fmcwPeak(cidx)), 'ro');
            plot([search_range(1) search_range(1)], [0 max(tmpys)], '-r')
            plot([search_range(end) search_range(end)], [0 max(tmpys)], '-r')
            xlim([0 Fs/2]);
            ylim([0 max(tmpys)]);
            xlabel('Frequency (Hz)');
            ylabel('Magnitude');
            title(sprintf('FMCW: Peak=%dHz', fmcwPeak(cidx)))

            subplot(3,1,2); hold on;
            plot(tmpys, '-b.');
            plot(fmcwPeak(cidx), tmpys(fmcwPeak(cidx)), 'ro');
            maxy = max(tmpys(search_range));
            plot([search_range(1) search_range(1)], [0 maxy], '-r')
            plot([search_range(end) search_range(end)], [0 maxy], '-r')
            xlim([0 search_range(end)]);
            ylim([0 maxy]);
            xlabel('Frequency (Hz)');
            ylabel('Magnitude');
            title(sprintf('Chirp %d/%d: Peak=%d', cidx, nChirps, fmcwPeak(cidx)))

            subplot(3,1,3); hold on;
            tmp_stdidx = Ke*(cidx-1) + startIndex;
            tmp_endidx = K-1 + Ke*(cidx-1) + startIndex;
            tmp_stdidx2 = max(1, tmp_stdidx - Ke);
            tmp_endidx2 = min(length(y), tmp_endidx + Ke);
            tmp = y(tmp_stdidx2:tmp_endidx2);
            plot(tmp, '-b');
            plot([tmp_stdidx-tmp_stdidx2 tmp_stdidx-tmp_stdidx2], [min(tmp) max(tmp)], '-r')
            plot([tmp_endidx-tmp_stdidx2 tmp_endidx-tmp_stdidx2], [min(tmp) max(tmp)], '-r')
            xlabel('Time');
            ylabel('Magnitude');
            title('Received Audio');
            pause(0.01)
        end
        cidx = cidx + 1;
    end

    fmcwDist = FmcwFreq2Dist(fmcwPeak, chirp_len, B, vs);
    
    fh = figure(3); clf; 
    subplot(2,1,1); hold on;
    plot(fmcwTime, fmcwDist, '-bo');
    plot(gtTime, gtDist, '-r.');
    legend('Estimated', 'Real');
    xlim([START_TRACK fmcwTime(end)]);
    xlabel('Time (s)');
    ylabel('Distance (mm)');
    title('Distance');
    subplot(2,1,2); hold on;
    plot(fmcwTime, fmcwSNR, '-bo');
    xlim([START_TRACK fmcwTime(end)]);
    xlabel('Time (s)');
    ylabel('SNR');
    title('SNR');
    
end

function [dist] = FmcwFreq2Dist(freq, chirp_len, B, vs)
    dist = freq * vs * chirp_len / B / 2;
end

function [freq] = FmcwDist2Freq(dist, chirp_len, B, vs)
    freq = dist * 2 * B / vs / chirp_len;
end

function [mag] = attenuation(dist)
    %% TODO: need a more realistic attenuation model
    max_dist = 20000;
    mag = power((max_dist-dist)/max_dist,2);
end
