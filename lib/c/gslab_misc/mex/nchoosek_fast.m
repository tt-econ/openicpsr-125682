%
% nchoosek_fast: C version of the "nchoosek" function in Matlab.
%


function out = nchoosek_fast(n,k)

assert(n>=k,'n must be >= k');
out = nchoosek_c(n,k);

end