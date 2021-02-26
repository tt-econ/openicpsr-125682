/*
mean_mat2D_c.c: computes the mean of the given 2D matrix.
e.g. mean([1,2,3]) returns 2.
*/


#include <mex.h> 

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    double *mat,*out,tempsum;
    int i,j,m,n;
    
	mat = mxGetPr(prhs[0]);
	n = mxGetN(prhs[0]);
	m = mxGetM(prhs[0]);
	plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
	out = mxGetPr(plhs[0]);
	tempsum = 0;
	for(i=0;i<n;i++){
		for(j=0;j<m;j++){
			tempsum += mat[i*m+j];
		}
	}
	out[0] = tempsum/m/n;
} 
