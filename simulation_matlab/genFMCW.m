function fmcw = genFMCW(fc, B, T, Fs)

u = @(t) 2*pi*(fc*t + B/(2*T)*t.^2);

t = (0:1/Fs:T-1/Fs)';

fmcw = exp(1i*u(t));
% H = hann(length(fmcw));
% fmcw = fmcw.*H;

% fmcw = [fmcw;zeros(100,1)];

end