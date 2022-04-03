function [dist] = FmcwFreq2Dist(freq, chirp_len, B, vs)
    dist = freq * vs * chirp_len / B;
end
