/*
nchoosek_c.c: C version of the matlab function "nchoosek".
e.g. nchoosek(6, 3) = 6!/(3!*(6-3)!) = 6 / 3 * 5 / 2 * 4 / 1 = 20.
*/


#include <mex.h> 
#ifndef min
	#define min(a, b) (((a) < (b)) ? (a) : (b))
#endif

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
	double *n, *k, *out;
	int multiplier, divisor;
	double result;
	int i, r;

	// get inputs
    n = mxGetPr(prhs[0]);
	k = mxGetPr(prhs[1]);
	
	// assign output
	plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
	out = mxGetPr(plhs[0]);
	
	// nchoosek(n, k) = nchoosek(n, n - k);
	r = min((int) k[0], (int) n[0] - (int) k[0]);
	
	multiplier = (int) n[0];
	divisor = 1;
	result = 1;
	
	for(i = 1; i <= r; i++){
		result = result * multiplier / divisor;
		multiplier --;
		divisor ++;
	}
	
	out[0] = result;
} 
