function [yf,n,wn]=LPFilter(y,Fs,fp,guard,ripp,atten)

    wn = fp/Fs*2;
    wg = (fp+guard)/Fs*2;
    [n,wn] = buttord(wn,wg,ripp,atten);
    [b,a] = butter(n,wn);
    % disp('============a');
    % fprintf('%.15f\n', a);
    % disp('============b');
    % fprintf('%.15f\n', b);
    % pause
    y = y.';
    yf = filter(b,a,y);
    yf = yf.';

end
