/*
SEQWITHIN.C

This function takes one input arguments as the "group" matrix.

The function sorts the "group" matrix by rows, and assigns an index "k"
to each row that indicates the row being the "k-th" appearance of the 
same group.

The first output is a list of these indices, 
and the second output contains the row-sorted groups.
 
For example, if we apply seqwithin to the following "group" matrix:

group = [ 2 2;  
          1 1;        
          3 3;         
          2 2;
          3 3;
          1 1;
          3 3 ]     

The outputs will be:

indices = [ 1;    sorted_groups = [ 1 1;
            2;                      1 1;
            1;                      2 2;
            2;                      2 2;
            1;                      3 3;
            2;                      3 3;
            3 ]                     3 3 ]

*/
#include <mex.h>

///////////////////////////////
// function declarations
///////////////////////////////
static void check_input(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
static void seq_within(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
static void allocate_mem(double ****group_row, int nrow, int ncol);
static void format_groups(double ***group_row, double *group, int nrow, int ncol);
static double compare_group(const void *a, const void *b, const void *struc);   
void quicksort(double ***arr, double ***brr, int elements, 
    double (*cmp_ptr)(const void *, const void *, const void*), void *struc);       
static void produce_output(double *ind_out, double *grp_out, 
    double ***group_row, int nrow, int ncol);
static void free_group_row(double ***group_row, int nrow);

///////////////////////////////
// function definitions
///////////////////////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
    check_input(nlhs, plhs, nrhs, prhs);
    seq_within(nlhs, plhs, nrhs, prhs);
}

static void check_input(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
    int nrow, ncol;

	// Check number of inputs
	if (nrhs != 1) {
		mexErrMsgTxt("There must be exactly one input field: the group matrix.\n");
	}
	if (nlhs > 2) {
		mexErrMsgTxt("There can not be more than 2 output field.\n");
	}

    // Check input types
    if (!mxIsDouble(prhs[0])){
        mexErrMsgTxt("Input group matrix must be of type double.");
    }
    
    // Check sizes
    nrow = (int)mxGetM(prhs[0]);
    ncol = (int)mxGetN(prhs[0]);
    if (nrow==0 || ncol==0) {
		mexErrMsgTxt("Input group matrix cannot be empty.\n");
    }
}

static void seq_within(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
    int nrow, ncol;
    double *group, ***group_row, *ind_out, *grp_out, ***val_row = NULL;
     
    // get inputs and input sizes
    group = mxGetPr(prhs[0]);
    nrow = mxGetM(prhs[0]);
    ncol = mxGetN(prhs[0]);

    // get pointer for output
    plhs[0] = mxCreateDoubleMatrix(nrow, 1, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(nrow, ncol, mxREAL);
    ind_out = mxGetPr(plhs[0]);
    grp_out = mxGetPr(plhs[1]);
    
    // allocate mem
    allocate_mem(&group_row, nrow, ncol);
    
    // sort according to groups 
    format_groups(group_row, group, nrow, ncol);
    quicksort(group_row, val_row, nrow, &compare_group, &ncol);
    
    produce_output(ind_out, grp_out, group_row, nrow, ncol);
    
    // free mem
    free_group_row(group_row, nrow);
}

static void allocate_mem(double ****group_row, int nrow, int ncol){
    int i;
    
    *group_row = mxMalloc(nrow* sizeof(double**));
    for(i=0; i<nrow; i++){
        *(*group_row+i) = mxMalloc(ncol* sizeof(double*));
    }
}

// format group into an array of pointers, with each pointer pointing
//   to one row of the original matrices. A row of data is represented
//   by another array of pointers pointing to the original data.
static void format_groups(double ***group_row, double *group, int nrow, int ncol){
    int i, j;
    
    for(i=0; i<nrow; i++){
        for(j=0; j<ncol; j++){
            group_row[i][j] = group + j*nrow + i;
        }        
    }
}

// a comparison function used for sorting
static double compare_group(const void *a, const void *b, const void *struc){
    int i, group_len;
    
    group_len = *(int*)struc;
    for(i=0; i<group_len; i++){
        if(*((double**)a)[i] > *((double**)b)[i]){
            return 1;
        }
        if(*((double**)a)[i] < *((double**)b)[i]){
            return -1;
        }
    }
    return 0;
}

// produce indices within group as the first output 
//   and save the sorted groups as the second output
static void produce_output(double *ind_out, double *grp_out, 
                   double ***group_row, int nrow, int ncol){
    int i, j;
    
    ind_out[0] = 1;
    for(i=1; i<nrow; i++){
        if(compare_group(group_row[i], group_row[i-1], &ncol)==0){
            ind_out[i] = ind_out[i-1] + 1;
        }else{
            ind_out[i] = 1;
        }
    }    

    for(i=0; i<nrow; i++){
        for(j=0; j<ncol; j++){
            grp_out[j*nrow+i] = *(group_row[i][j]);
        }
    }
}

// free memory
static void free_group_row(double ***group_row, int nrow){
    int i;
    
    for(i=0;i<nrow;i++){
        mxFree(group_row[i]);
    }
    mxFree(group_row);
}

