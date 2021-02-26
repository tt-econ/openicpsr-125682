/*
TRANSFORM_GROUP.C
Communicate with Matlab to get the input with a vector whose elements are organized in groups,  
with each group having a given variance-covariance matrix and do a transformation 
by multiplying each group with the square root of its var-cov matrix (obtained by
Cholesky decomposition if positive definite and spectral decomposition otherwise).

Note that a one-dimensional vector can enter either as 1 x n or n x 1 length and there is
no distinction.

Input parameters in order of entry:
    data:               nobs x 1 vector of data
    group:              nobs x 1 vector of elements indicating the group that each of the data
                        point belongs to
    vcov:               nvcov x 1 cell array of unique variance-covariance matrices
                        Each entry in the cell array is a square positive semi-definite 
                        symmetric matrix representing a unique variance-covariance matrix of a group
    vcov_id:            ngroup x 1 vector
                        vcov_id[i] is the index of the vcov matrix of group i
                        
Output parameter:
    output:             nobs x 1: the transformed vector
                        For each group, this is sqrt(vcov of the group) x data
                            with elements of the group  
*/

#include <mex.h> 
#include <math.h>

#define MAX(a, b) (((a) > (b)) ? (a) : (b))
#define MIN(a, b) (((a) < (b)) ? (a) : (b))

#define ROTATE(v, i, j, k, l) g = v[i][j]; h = v[k][l]; v[i][j] = g - s*(h + g*tau);\
                              v[k][l] = h + s*(g - h*tau);


#define NUM_RHS         4
#define NUM_LHS         1

static int check_and_get_dimensions(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[],
                                    int *p_nobs, int *p_ngroup, int *p_nvcov);
    
static int *find_group_size(const double *data, const double *group, int nobs, int ngroup);

static double ***find_all_transform(const mxArray *vcov, int nvcov, 
                                    int** vcov_dims, int *vcov_type);

static int calc_chol(const double *vcov, int ngroup, double ** chol);

static void calc_spectral(const double *vcov, int n, int *nrot, double ** spectral);

static void calc_output(const double *data, int *group_size, const double *vcov_id, 
                        int ngroup, int ** vcov_dims, double *** all_transform, 
                        int *vcov_type, double *output);    
                        
static void free_transform(double ***all_transform, int nvcov, int** vcov_dims);
   
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int good_input;    
    const mxArray *vcov;
    const double *data, *group, *vcov_id;
    int *group_size, **vcov_dims, *vcov_type;
    double *output;
    double ***all_transform;
    
    int nobs, ngroup;
    int nvcov;

	// check inputs and get input dimensions
	good_input = 
        check_and_get_dimensions(nlhs, plhs, nrhs, prhs, &nobs, &ngroup, &nvcov);
	if (!good_input) {		
		mexErrMsgTxt("One or more input errors found - see details above.");
	}	
    
    // get pointers to input
	data = mxGetPr(prhs[0]);
	group = mxGetPr(prhs[1]);
	vcov = prhs[2];
    vcov_id = mxGetPr(prhs[3]);

	// allocate output matrix
	plhs[0] = mxCreateDoubleMatrix(nobs, 1, mxREAL);
	
	// assign output pointer
	output = mxGetPr(plhs[0]);
    
    group_size = find_group_size(data, group, nobs, ngroup);

    vcov_dims = mxMalloc(nvcov * sizeof(*vcov_dims));    
    vcov_type = mxMalloc(nvcov * sizeof(int));
    all_transform = find_all_transform(vcov, nvcov, vcov_dims, vcov_type);	
    
    calc_output(data, group_size, vcov_id, ngroup, vcov_dims, all_transform, vcov_type, output);
    
    free_transform(all_transform, nvcov, vcov_dims);    
    mxFree(group_size);
    mxFree(vcov_dims);
    mxFree(vcov_type);
}

static int check_and_get_dimensions(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[],
                             int *p_nobs, int *p_ngroup, int *p_nvcov) {
    
    int isOK, i;
    int num_dim[NUM_RHS];
    int* dims[NUM_RHS];

	// check number of inputs and outputs
	if (nrhs != NUM_RHS) {
		mexErrMsgTxt("There should be a total of 4 input fields: data vector, group index vector and vcov cell array and vcov id vector.\n");
	}
	if (nlhs > NUM_LHS) {
		mexErrMsgTxt("There can not be more than 1 output field: the tranformed vector.\n");
	}        
  
    // get input dimensions
	for (i = 0; i < nrhs; i++) {
		num_dim[i] = (int) mxGetNumberOfDimensions(prhs[i]);
		dims[i] = (int*) mxGetDimensions(prhs[i]);
	}
    
	isOK = 1;

	// Check data vector	
	if ((num_dim[0] > 2) || (MIN(dims[0][0], dims[0][1]) != 1)) {
		mexPrintf("First input (data vector) should have dimension nobs x 1.\n");
		isOK = 0;
	}
    
	*p_nobs = MAX(dims[0][0], dims[0][1]);
	
	// Check group vector	
	if ((num_dim[1] > 2) || (MIN(dims[1][0], dims[1][1]) != 1) || 
        (MAX(dims[1][0], dims[1][1]) != *p_nobs)) {
		mexPrintf("Second input (group vector) should have dimension nobs x 1.\n");
		isOK = 0;
	}	     

	// Check vcov cell array  
    if (!mxIsCell(prhs[2])) {
        mexPrintf("Third input should be a cell array.\n");
        isOK = 0;
    }
    
    *p_nvcov = (int) mxGetNumberOfElements(prhs[2]);
    
	// Check vcov_id vector	
	if ((num_dim[3] > 2) || (MIN(dims[3][0], dims[3][1]) != 1)) {
		mexPrintf("Fourth input (vcov index) should have dimension ngroup x 1.\n");
		isOK = 0;
	}	     
    
    *p_ngroup = MAX(dims[3][0], dims[3][1]);
    
	return isOK;
}

static int *find_group_size(const double *data, const double *group, int nobs, int ngroup) {
    int i;
    int sorted;
    int *group_size;

    // Check if group is already sorted, and find group_size
    group_size = mxCalloc(ngroup, sizeof(*group));
    sorted = 1;
    for (i = 0; i < nobs - 1; i++) {
        if (sorted && (group[i] > group[i + 1])) {  
            sorted = 0;
        }
        group_size[(int) group[i] - 1]++;
    }
    group_size[(int) group[nobs - 1] - 1]++;
    
    if (!sorted) {
        mexErrMsgTxt("Group index should be sorted.\n");        
    }    
    if (ngroup != (int) group[nobs - 1]) {
        mexErrMsgTxt("Group indexing is not correct.\n");        
    }
    if ((int) group[0] != 1) {
        mexErrMsgTxt("Group indexing is not correct.\n");        
    }

    return group_size;
}

static double ***find_all_transform(const mxArray *vcov, int nvcov, int **vcov_dims, int *vcov_type) {
    int i, j;
    int ndim;
    int posdef;
    int nrot;
    double ***all_transform;
    const double *vcov_matrix;
    const mxArray *single_vcov;
    
    // Allocate nvcov of pointers to pointers of double
    // to store all the unique Cholesky/spectral factorizations
    all_transform = mxMalloc(nvcov * sizeof(double **));    
    
    
    for (i = 0; i < nvcov; i++) {    
        // Allocate all_transform[i] pointing to a dynamic matrix with same size as vcov{i}
        single_vcov = mxGetCell(vcov, i);
        vcov_matrix = mxGetPr(single_vcov);
        ndim = mxGetNumberOfDimensions(single_vcov);
        vcov_dims[i] = (int*) mxGetDimensions(single_vcov);
        if (ndim > 2) {
            mexErrMsgTxt("Each varcov matrix has to have 2 dimensions.\n");
        }
        if (vcov_dims[i][0] != vcov_dims[i][1]) {
            mexErrMsgTxt("Each varcov matrix has to be square.\n");
        }
        all_transform[i] = mxMalloc(vcov_dims[i][0] * sizeof(double *));
        for (j = 0; j < vcov_dims[i][0]; j++) {
            all_transform[i][j] = mxCalloc(vcov_dims[i][1], sizeof(double));                
        }
        // Start with calculating the Cholesky factorization for vcov i
        // This will also check for positive definiteness
        posdef = calc_chol(vcov_matrix, vcov_dims[i][0], all_transform[i]);        
        
        // if not positive definite, find the Spectral factorization for vcov i 
        if (!posdef) 
            calc_spectral(vcov_matrix, vcov_dims[i][0], &nrot, all_transform[i]);

        vcov_type[i] = posdef;
    }
    
    return all_transform;
}

static int calc_chol(const double *vcov, int ngroup, double ** chol) {
    int i, j, k;
    double sum;   
    
    // Standard Cholesky factorization
    // chol is a lower triangle matrix
    for (i = 0; i < ngroup; i++) {
        for (j = i; j < ngroup; j++) {
            for (sum = vcov[i * ngroup + j], k = i - 1; k >= 0; k--) {
                sum -= chol[i][k] * chol[j][k];
            }            
            if (i == j) {
                if (sum <= 0.0) { // not positive definite
                    return 0;
                }
                chol[i][i] = sqrt(sum);
            } else chol[j][i] = sum / chol[i][i];
        }        
    }
    return 1;
}

// Spectral decomposition (or Eigendecomposition)
// Adapted by Linh from jacobi() function in Section 11.1 of Numerical Recipes in C v2
static void init_spectral(const double *vcov, int n, double ***p_a, double ***p_v,
                          double **p_d, double **p_b, double **p_z);
static void finalize_spectral(int n, double **a, double **v, double *d, double *b, double *z, 
                              double **spectral);                      
static void calc_spectral(const double *vcov, int n, int *nrot, double **spectral) {
// Computes all eigenvalues and eigenvectors of a real symmetric matrix vcov[n*n]. 
// a[0..n-1][0..n-1] is initialized to vcov[n*n] and used in the rotations
// On output, elements of a above the diagonal are destroyed. 
// nrot returns the number of Jacobi rotations that were required.
// spectral = v * sqrt(d) in which:
// d[0..n-1] returns the eigenvalues of vcov.
// v[0..n-1][0..n-1] is a matrix whose columns contain, on output, the normalized eigenvectors of 
// vcov. 

    int j, iq, ip, i;
    double tresh, theta, tau, t, sm, s, h, g, c, *b, *z;    
    double *d, **v, **a;
    
    init_spectral(vcov, n, &a, &v, &d, &b, &z);
    *nrot = 0;
    for (i = 1; i <= 150; i++) { // counting the number of sweeps
        sm = 0.0;
        for (ip = 0; ip < n-1; ip++) { // Sum off-diagonal elements.
            for (iq = ip+1; iq < n; iq++) 
                sm += fabs(a[ip][iq]);
        }
        if (sm == 0.0) { // The normal return, which relies on quadratic convergence to machine underflow.
            finalize_spectral(n, a, v, d, b, z, spectral);
            return;
        }
        if (i < 4)
            tresh = 0.2 * sm / (n*n); // ...on the first three sweeps.
        else
            tresh = 0.0; // ...thereafter.
        for (ip = 0; ip < n-1; ip++) {
            for (iq = ip+1; iq < n; iq++) {
                g = 100.0 * fabs(a[ip][iq]);
                // After four sweeps, skip the rotation if the off-diagonal element is small.
                if ((i > 4) && ((fabs(d[ip]) + g) == fabs(d[ip]))
                    && ((fabs(d[iq])+g) == fabs(d[iq]))) {
                    a[ip][iq] = 0.0;
                }
                else if (fabs(a[ip][iq]) > tresh) {
                    h = d[iq] - d[ip];
                    if ((fabs(h) + g) == fabs(h))
                        t = (a[ip][iq])/h; // t = 1/(2\theta)
                    else {
                        theta = 0.5 * h / (a[ip][iq]); // Equation (11.1.10).
                        t = 1.0/(fabs(theta) + sqrt(1.0 + theta*theta));
                        if (theta < 0.0) t = -t;
                    }
                    c = 1.0/sqrt(1 + t * t);
                    s = t * c;
                    tau = s / (1.0 + c);
                    h = t * a[ip][iq];
                    z[ip] -= h; 
                    z[iq] += h; 
                    d[ip] -= h; 
                    d[iq] += h;
                    a[ip][iq] = 0.0;
                    for (j = 0; j <= ip-1; j++) {  // Case of rotations 0 <= j < p
                        ROTATE(a, j, ip, j, iq)
                    }
                    for (j = ip+1; j <= iq-1; j++) { // Case of rotations p < j < q
                        ROTATE(a, ip, j, j, iq)
                    }
                    for (j = iq+1; j < n; j++) { // Case of rotations q < j < n
                        ROTATE(a, ip, j, iq, j)
                    }
                    for (j = 0; j < n; j++) {
                        ROTATE(v, j, ip, j, iq)
                    }
                    ++(*nrot);
                }
            }
        }
        for (ip = 0; ip < n; ip++) {
            b[ip] += z[ip];
            d[ip] = b[ip]; // Update d with the sum of tapq,
            z[ip] = 0.0; // and reinitialize z.
        }
    }    
    mexErrMsgTxt("Too many iterations in routine jacobi - cannot find the spectral decomposition.");
}
static void init_spectral(const double *vcov, int n, double ***p_a, double ***p_v,
                       double **p_d, double **p_b, double **p_z) {
        int it, jt;         
                 
        *p_v = mxMalloc(n * sizeof(double*)); 
        *p_a = mxMalloc(n * sizeof(double*));
        for (it = 0; it < n; it++) {
            (*p_v)[it] = mxCalloc(n, sizeof(double));
            (*p_a)[it] = mxMalloc(n * sizeof(double));
            for (jt = 0; jt < n; jt++) {
                (*p_a)[it][jt] = vcov[it + jt * n];
            }
        }
        *p_b = mxMalloc(n * sizeof(double));
        *p_z = mxMalloc(n * sizeof(double));
        *p_d = mxMalloc(n * sizeof(double));
        // Initialize to the identity matrix.
        for (it = 0; it < n; it++) (*p_v)[it][it] = 1.0;
        for (it = 0; it < n; it++) { // Initialize b and d to the diagonal of vcov.
            (*p_b)[it] = (*p_d)[it] = (*p_a)[it][it];
            (*p_z)[it] = 0.0; // This vector will accumulate terms of the form tapq 
                              // as in equation (11.1.14).
        }
    }
    
static void finalize_spectral(int n, double **a, double **v, double *d, double *b, double *z, 
                           double **spectral) {
        int it, jt;
        
        mxFree(z);
        mxFree(b);
        // Calculate sqrt(d), saved into d itself
        for (it = 0; it < n; it++) {
            if (d[it] < -1e-6)
                mexErrMsgTxt("Variance-covariance matrix should be positive semi-definite.");
            if (d[it] < 0.0)
                d[it] = 0.0;
            d[it] = sqrt(d[it]);
        }
        // Calculate spectral = v * sqrt(d)
        for (it = 0; it < n; it++) {
            for (jt = 0; jt < n; jt++) 
                spectral[it][jt] = v[it][jt] * d[jt];
        }
        mxFree(d);
        for (it = 0; it < n; it++) {
            mxFree(v[it]);
            mxFree(a[it]);
        }
        mxFree(v);
        mxFree(a);
    }

static void calc_output(const double *data, int *group_size, const double *vcov_id, 
                 int ngroup, int ** vcov_dims, double *** all_transform, 
                 int *vcov_type, double *output) {
    
    int i, j, k, id;
    int oi, vi, maxk;
    int vi_group;
    
    // Sparse matrix multiplication
    oi = 0;
    vi_group = 0;
    
    for (i = 0; i < ngroup; i++) {                
        output[oi] = 0;        
        id = (int) vcov_id[i] - 1;
        if (group_size[i] != vcov_dims[id][0]) {
            mexErrMsgTxt("Dimensions of a group's variance covariance matrix do not match with its group size.\n");
        }
        maxk = group_size[i];
        for (j = 0; j < group_size[i]; j++) {
            vi = vi_group;   
            if (vcov_type[id] == 1) { // positive definite vcov
                // Consider only the lower left of the group's var-cov Cholesky factorization
                maxk = j + 1;
            }
            for (k = 0; k < maxk; k++) {
                output[oi] += all_transform[id][j][k] * data[vi];
                vi++;
            }
            oi++;
        }
        vi_group += group_size[i];
    }
}

static void free_transform(double ***all_transform, int nvcov, int ** vcov_dims) {
    int i, j;
    
    for (i = 0; i < nvcov; i++) {
        for (j = 0; j < vcov_dims[i][0]; j++) {
            mxFree(all_transform[i][j]);
        }
        mxFree(all_transform[i]);
    }    
    mxFree(all_transform);
}