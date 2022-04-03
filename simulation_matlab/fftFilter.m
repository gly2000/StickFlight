function [y] = fftFilter(y, Fs, fl, fu, guard)

  Y = fft(y);
  N = numel(Y);
  Nl = floor(fl/Fs*N);
  Nu = ceil(fu/Fs*N);
  Ng = floor(guard/Fs*N);

  filter=zeros(1,N);
  filter(Nl:Nu)=1;
  filter(N+2-Nu:N+2-Nl)=1;
  filter(Nl-Ng:Nl)=cos((Ng:-1:0)/Ng*pi/2);
  filter(N+2-Nl:N+2-Nl+Ng)=cos((0:Ng)/Ng*pi/2);
  filter(Nu:Nu+Ng)=cos((0:Ng)/Ng*pi/2);
  filter(N+2-Nu-Ng:N+2-Nu)=cos((Ng:-1:0)/Ng*pi/2);
  Y=Y.*filter;
  y=ifft(Y);
end