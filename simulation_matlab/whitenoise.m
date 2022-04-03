function [rx, phases] = whitenoise(T, Fs, ENC)

    if nargin < 1, T   = 0.2;    end   %% FMCW chirp length 
    if nargin < 2, Fs  = 48e3;   end   %% Sampling rate
    if nargin < 3, ENC = 'fmcw'; end   %% Type of signal

    rng(1);
    DEBUG = 1;

    n = Fs*T;
    phases = zeros(n,1);
    phases(1) = 0;
    
    
    if(mod(n,2) == 0)
        for ti = 2:n/2
            phases(ti) =  rand(1)*2 - 1; %% [-1, 1]
            phases(n + 2 - ti) =  -phases(ti);  %% symmetric
        end
    end

    if 0
        figure(1); clf; hold on;
        plot(phases, '-b.');
        pause
    end

    phases = phases*2*pi; %% [-2pi, 2pi]

    
    freq = exp(1j*(phases));

    
    switch ENC
        case 'null'
            rx = ifft(freq);
        case 'fmcw'
            B = 3e3;
            
            for fc = 6e3:B:20e3
                fmcw = genFMCW(fc,B,T,Fs);
                fmcw_freq = fft(fmcw);
                bw = fc*T:1:(fc+B)*T;
                idx = false(n,1);
                idx([bw+1,n + 1 - bw]) = true;
                % fmcw_freq(~idx) = 0;
                % figure
                % ff = 1:n+1;
                % plot(ff,abs(fmcw_freq));
                % hold on
                % plot(ff(idx),abs(fmcw_freq(idx)),'o');
                pdif = angle(fmcw_freq(idx)) - angle(freq(idx));
                freq(idx) = freq(idx).*exp(1j*(pdif));
            end
            rx = ifft(freq);
    

            if DEBUG
                figure(1); clf;
                % spectrogram(rx, 256, 250, 256, Fs, 'yaxis');
                win      = floor(Fs/32);
                noverlap = floor(win*9/10); % 75% overlap
                Nfft = Fs;
                [S,F,X,P] = spectrogram(rx, win, noverlap, Nfft, Fs);

                figure(1); clf;
                imagesc(X, F, abs(S));
                colorbar;
                ax = gca; ax.YAxis.Exponent = 0;
                set(gca,'YDir','normal') 
                ylim([0 Fs/2]);
                xlabel('Time (s)');
                ylabel('Frequency (Hz)');
                title('Time-Frequency plot of a Audio signal');
                % pause
            end

        % case 'zc'
        %     df = Fs/(n-1);
        %     f1 = 17e3/df;
        %     f2 = 23e3/df;
        %     zc = genZC(f2-f1+1)';%column vector
        %     pdif = angle(zc) - angle(freq(f1:f2));
        %     freq(f1:f2) = freq(f1:f2).*exp(1j*pdif);
        %     rx = ifft(freq);
            
        otherwise
            disp('enter a valid encoder.')
            rx = [];
    end
    % rx = repmat(rx,[20,1]);


end
