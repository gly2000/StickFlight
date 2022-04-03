function [freq] = FmcwDist2Freq(dist, chirp_len, B, vs)
    freq = dist * B / vs / chirp_len;
end