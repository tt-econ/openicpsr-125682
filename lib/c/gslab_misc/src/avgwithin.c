/*
AVGWITHIN.C

This function takes two input arguments:
1) a "value" matrix, 
2) a "group" matrix.

For each column of the "value" matrix, this function computes 
the average value by each unique group (a group is defined by an entire 
row in the "group" matrix). The function then arranges the output
by the unique and sorted rows of the "group" matrix.

Each column of the first output contains averaged value by group,
and the second output contains the unique and sorted groups.
 
For example, if we apply avgwithin to the following two arguments:

value = [ 1 2;    group = [ 4 5;
          3 4;              1 2;
          5 6;              4 5;
          7 8 ]             3 3 ]

The outputs will be:

averaged_value = [ 3 4;     unique_sorted_groups = [ 1 2;
                   7 8;                              3 3;
                   3 4 ]                             4 5 ]

*/

#include "operate_within.h"

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    char oper[4]="avg";
    
    check_input(nlhs, plhs, nrhs, prhs);
    operate_within(nlhs, plhs, nrhs, prhs, oper);
}


