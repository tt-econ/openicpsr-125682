%
% factorial_fast: C version of the "factorial" function in Matlab
%


function out = factorial_fast(n)

assert(n>=0,'n must non-negative');

out = factorial_c(n);

end