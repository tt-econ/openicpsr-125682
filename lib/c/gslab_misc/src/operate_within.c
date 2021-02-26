/*
  This script containts the operation functions for the following scripts:
  1) sumwithin.c;
  2) avgwithin.c;
  3) prodwithin.c.
  
  Please see each individual script for its usage. The algorithm 
  is common to all scripts, and it is the following:
  1) convert the input pointer array of values and groups into 
     two-dimensional array of pointers to facilitate sorting
  2) sort according to groups
  3) find the number of groups and their starting indices in the 
     sorted list of groups
  4) apply operations on values by groups and save output
*/

#include "operate_within.h"
///////////////////////////////
// function declarations
///////////////////////////////
static void choose_operation(double (**funcptr)(double ***, int, int, int *), const char *oper);
static void allocate_mem(double ****val_row, double ****group_row, int **group_ind, int nrow, 
    int ncol_val, int ncol_grp);
static void org_into_row_array(double ***val_row, double ***group_row, double *value_in, 
    double *group_in, int nrow, int ncol_val, int ncol_grp);
static double compare_group(const void *a, const void *b, const void *struc);   
static int find_numgroups(int *group_ind, double ***group_row, int nrow, int ncol_grp);   
static void apply_operator_by_group(double *value_out, double ***val_row, 
    int *group_ind, double (*funcptr)(double ***, int, int, int *), 
    int numgroups, int ncol_val);
static void format_unique_groups(double *grpout, double ***group_row, int *group_ind, 
    int numgroups, int ncol_grp);
static void free_mem(int *group_ind, double ***valRow, double ***groupRow, int nrow);     
static double sum(double ***data, int row, int col, int *group_ind);
static double avg(double ***data, int row, int col, int *group_ind);
static double prod(double ***data, int row, int col, int *group_ind);
       
///////////////////////////////
// control functions
///////////////////////////////
void check_input(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
    int nrow_val, ncol_val, nrow_grp, ncol_grp;

	// Check number of inputs
	if (nrhs != 2) {
		mexErrMsgTxt("There must be 2 input fields: value matrix and group matrix.\n");
	}
	if (nlhs > 2) {
		mexErrMsgTxt("There can not be more than 2 output field.\n");
	}

    // Check input types
    if (!mxIsDouble(prhs[0]) || !mxIsDouble(prhs[1])){
        mexErrMsgTxt("Input matrices must be of type double.");
    }
    
    // Check sizes
    nrow_val = (int)mxGetM(prhs[0]);
    ncol_val = (int)mxGetN(prhs[0]);
	nrow_grp = (int)mxGetM(prhs[1]);
    ncol_grp = (int)mxGetN(prhs[1]);
    if (nrow_val==0 || ncol_val==0 || nrow_grp==0 || ncol_grp==0) {
		mexErrMsgTxt("Input matrices cannot be empty.\n");
    }
    if (nrow_val != nrow_grp) {
		mexErrMsgTxt("First and second input matrices must have the same number of rows.\n");
    }    
}

// main control function
void operate_within(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[], const char *oper){
    int nrow, ncol_val, ncol_grp, *group_ind, numgroups;
    double *value_in, *group, *vout, *grpout, ***val_row, ***group_row;
    double (*funcptr)(double ***, int, int, int *);
    
    // choose the correct operation to apply 
    // (currently supports "sum", "avg", and "prod")
    choose_operation(&funcptr, oper);
    
    // get inputs and input sizes
    value_in = mxGetPr(prhs[0]);
    group = mxGetPr(prhs[1]);
    nrow = mxGetM(prhs[0]);
    ncol_val = mxGetN(prhs[0]);
    ncol_grp = mxGetN(prhs[1]);
    
    // allocate mem
    allocate_mem(&val_row, &group_row, &group_ind, nrow, ncol_val, ncol_grp);

    // sort according to groups 
    org_into_row_array(val_row, group_row, value_in, group, nrow, ncol_val, ncol_grp);
    quicksort(group_row, val_row, nrow, &compare_group, &ncol_grp);
    
    // find number of groups and a list of starting indices
    numgroups = find_numgroups(group_ind, group_row, nrow, ncol_grp);
    
    // get pointer for output
    plhs[0] = mxCreateDoubleMatrix(numgroups, ncol_val, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(numgroups, ncol_grp, mxREAL);
    vout = mxGetPr(plhs[0]);
    grpout = mxGetPr(plhs[1]);
    
    // apply operation to sorted input values by their groups
    apply_operator_by_group(vout, val_row, group_ind, funcptr, numgroups, ncol_val);
    
    // save unique groups for output
    format_unique_groups(grpout, group_row, group_ind, numgroups, ncol_grp);
    
    // free mem
    free_mem(group_ind, val_row, group_row, nrow);
}

// choose the correct operation to apply 
// (currently supports "sum", "avg", and "prod")
static void choose_operation(double (**funcptr)(double ***, int, int, int *), const char *oper){
    if(strcmp(oper, "sum")==0){
        *funcptr = &sum;
    }else if(strcmp(oper, "prod")==0){
        *funcptr = &prod;
    }else if(strcmp(oper, "avg")==0){
        *funcptr = &avg;
    }
}

// allocate mem
static void allocate_mem(double ****val_row, double ****group_row, int **group_ind, int nrow, 
                  int ncol_val, int ncol_grp){
    int i;
    
    *group_ind = mxMalloc((nrow+1) * sizeof(int));
    *val_row = mxMalloc(nrow * sizeof(double**));
    *group_row = mxMalloc(nrow * sizeof(double**));
    for(i=0; i<nrow; i++){
        *(*val_row+i) = mxMalloc(ncol_val * sizeof(double*));
        *(*group_row+i) = mxMalloc(ncol_grp * sizeof(double*));
    }
}

// format input matrices into arrays of pointers, with each pointer
//   pointing to one row of the original matrices. A row of data is 
//   represented by another array of pointers pointing to the original data.
static void org_into_row_array(double ***val_row, double ***group_row, double *value_in, 
                     double *group_in, int nrow, int ncol_val, int ncol_grp){
    int i, j;
    
    for(i=0; i<nrow; i++){
        for(j=0; j<ncol_val; j++){
            val_row[i][j] = value_in + j*nrow + i;
        }
        for(j=0; j<ncol_grp; j++){
            group_row[i][j] = group_in + j*nrow + i;
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

// find number of groups and a list of starting indices
static int find_numgroups(int *group_ind, double ***group_row, int nrow, int ncol_grp){
    int numgroups, i;

    numgroups = 1;
    group_ind[0] = 0;
    for (i=1; i<nrow; i++) {
        if (compare_group(group_row[i], group_row[i-1], &ncol_grp)!=0) {
            group_ind[numgroups++] = i;
        }
    }
    group_ind[numgroups] = nrow;
    return numgroups;
}

// apply operation to sorted input values by their groups
static void apply_operator_by_group(double *value_out, double ***val_row, int *group_ind, 
                             double (*funcptr)(double ***, int, int, int *), int numgroups,
                             int ncol_val){
    int i, col;
    
    for(i=0; i<numgroups; i++){
        for(col=0; col<ncol_val; col++){
            value_out[col*numgroups+i] = (*funcptr)(val_row, i, col, group_ind);
        }
    }
}

// save unique groups for output
static void format_unique_groups(double *grpout, double ***group_row, int *group_ind, 
                          int numgroups, int ncol_grp){
    int i, j;
    
    for(i=0; i<numgroups; i++){
        for(j=0; j<ncol_grp; j++){
            grpout[j*numgroups+i] = *group_row[ group_ind[i] ][j];
        }
    }
}

// free memory
static void free_mem(int *group_ind, double ***val_row, double ***group_row, int nrow){
    int i;
    
    mxFree(group_ind);
    for(i=0; i<nrow; i++){
        mxFree(val_row[i]);
        mxFree(group_row[i]);
    }
    mxFree(val_row);
    mxFree(group_row);
}

///////////////////////////////
// Operation functions
///////////////////////////////
static double sum(double ***data, int row, int col, int *group_ind){
    double out=0;
    int i, len;
    
    len = group_ind[row+1] - group_ind[row];
    for(i=0; i<len; i++){
        out += *data[ group_ind[row]+i ][col];
    }
    return out;
}

static double prod(double ***data, int row, int col, int *group_ind){
    double out=1;
    int i, len;
    
    len = group_ind[row+1] - group_ind[row];
    for(i=0; i<len; i++){
        out *= *data[ group_ind[row]+i ][col];
    }
    return out;
}

static double avg(double ***data, int row, int col, int *group_ind){
    double out;
    int len;
    
    len = group_ind[row+1] - group_ind[row];
    out = sum(data, row, col, group_ind) / len;
    return out;
}