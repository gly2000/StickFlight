function maxIndex = syncFMCWSymbol(y,offsetIndex,y0,K)

L=2*K;
corr=zeros(1,L);

for i=1+offsetIndex:L+offsetIndex
    corr(i-offsetIndex)=y0*y((0:K-1)+i)';
end
% figure;  plot(abs(corr));
maxCorr=0;
maxIndex=0;
for i=1:L
    if abs(corr(i))>maxCorr
        maxCorr=abs(corr(i));
        maxIndex=i+offsetIndex;
    end
end
