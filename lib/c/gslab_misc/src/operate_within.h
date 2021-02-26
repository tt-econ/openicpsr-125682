/*
  This is the header script for the following scripts:
  1) sumwithin.c;
  2) avgwithin.c;
  3) prodwithin.c.
*/

#ifndef _OPERATE_WITHIN_H_
#define _OPERATE_WITHIN_H_

#include <mex.h>
#include <stdio.h>

void check_input(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);
void operate_within(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[], const char *oper);
void quicksort(double ***arr, double ***brr, int elements, 
    double (*cmp_ptr)(const void *, const void *, const void*), void *struc);

#endif
