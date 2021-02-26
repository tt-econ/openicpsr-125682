/*
factorial_c.c: C version of the matlab function "factorial".
e.g. factorial(5) = 5! = 120
*/


#include <mex.h> 

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
	double *n, *out;
	int i;
	double result;

    n = mxGetPr(prhs[0]);
	plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
	out = mxGetPr(plhs[0]);
    
	result = 1;
	for(i = 1; i <= (int) n[0]; i++){
		result = result * i;
	}
	out[0] = result;
} 
