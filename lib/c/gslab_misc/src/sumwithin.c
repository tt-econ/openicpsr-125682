/*
SUMWITHIN.C

This function takes two input arguments:
1) a "value" matrix,
2) a "group" matrix.
where the number of rows in each matrix is the same.

For each column of the "value" matrix, this function computes 
the sum of values by each unique group (a group is defined by an 
entire row in the "group" matrix). The function then arranges the 
output by the unique and sorted rows of the "group" matrix.

Each column of the first output contains summed value by group,
and the second output contains the unique and sorted groups.
 
For example, if we apply sumwithin to the following two arguments:

value = [ 1 2;    group = [ 3;
          3 4;              1;
          5 6;              3;
          7 8 ]             2 ]

The outputs will be:

summed_value = [ 3 4;     unique_sorted_groups = [ 1;
                 7 8;                              2;
                 6 8 ]                             3 ]

Note that the group matrix need not be a column vector; groups 
are determined by unique rows of the group matrix.               
*/

#include "operate_within.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
    char oper[4]="sum";
    
    check_input(nlhs, plhs, nrhs, prhs);
    operate_within(nlhs, plhs, nrhs, prhs, oper);
}


