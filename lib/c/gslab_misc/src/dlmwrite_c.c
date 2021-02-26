/*
For readme, please see dlmwrite_fast.m
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "mex.h"
#include "io64.h"

static FILE  *fp=NULL;

static void CloseStream(void)
{
  //mexPrintf("Closing file.\n");
  fclose(fp);
}

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    char *str, *mode, *type, *char_nan, *char_inf;
	char type_double[] = "double", type_float[] = "float", type_short[] = "short", type_int[] = "int", type_long[] = "long";
	int i,j,m,n;
	void *data_in, *data;
	char *input_buf;
    double* ptrDouble;
	float* ptrFloat;
	int* ptrInt;
	long int* ptrLong;
	short int* ptrShort;
	int* precision;
	(void) plhs;

	if (nrhs <2){
		mexErrMsgTxt("At least two arguments required.");
	}else if (nrhs>7){
		mexErrMsgTxt("Use at most seven arguments.");
	}
	if (nrhs > 2){
		str = mxArrayToString(prhs[2]);
	}else{
		str = ",";
	}
	if (nrhs > 4){
		mode = mxArrayToString(prhs[3]);
		if (strcmp(mode,"w") && strcmp(mode,"a")){
			mexErrMsgTxt("Invalid mode.");
		}
	}else{
		mode = "w";
	}
	if (nrhs >5 ){
		char_nan = mxArrayToString(prhs[4]);
		char_inf = mxArrayToString(prhs[5]);
	}
	if (nrhs == 7){
		precision = mxGetData(prhs[6]);
	}else{
		precision[0] = 4;
	}

	if (mxIsDouble(prhs[1])){
		//mexErrMsgTxt("!!");
		ptrDouble = mxGetData(prhs[1]);
		type = type_double;
		//mexPrintf("double\n");
		//(double*)data_in = ptrDouble;
	}else if (mxIsSingle(prhs[1])){
		ptrFloat = mxGetData(prhs[1]);
		type = type_float;
		//mexPrintf("single\n");
	}else if (mxIsInt32(prhs[1])){
		ptrLong = mxGetData(prhs[1]);
		type = type_long;
		//mexPrintf("long\n");
	}else{
		mxErrMsgTxt("Unknown type of input matrix.. Supported types: int8,int16,int32,single,double.");
	}
	//mexPrintf("Using \"%s\" as the delimiter...\n",str);
	//mexPrintf("Mode: \"%s\" ...\n",mode);

    input_buf = mxArrayToString(prhs[0]);
	
    if (fp==NULL){
		fp = fopen(input_buf, mode);
		if (fp == NULL){
			mexErrMsgTxt("Could not open file.");
		}
		//mexPrintf("Opening file \"%s\"...\n",input_buf);
		mexAtExit(CloseStream);
    }
	m = mxGetM(prhs[1]);
    n = mxGetN(prhs[1]);
	   
    //mexPrintf("Writing data to file.\n");
	if (!strcmp(type,"double")){
		//mexPrintf("double\n");
		for (i=0;i<m;i++){
			for (j=0;j<n-1;j++){
				if (mxIsNaN(ptrDouble[j*m+i])){
					fprintf(fp, "%s%s",char_nan,str);
				}else if (mxIsInf(ptrDouble[j*m+i])){
						fprintf(fp, "%s%s",char_inf,str);
				}else{
					fprintf(fp, "%.*f%s",*precision,(double)ptrDouble[j* m+i],str);
				}
			}
			if (mxIsNaN(ptrDouble[m* n-m+i])){
					fprintf(fp, "%s\n",char_nan,str);
				}else if (mxIsInf(ptrDouble[m* n-m+i])){
						fprintf(fp, "%s\n",char_inf,str);
			}else{
					fprintf(fp, "%.*f\n",*precision,(double)ptrDouble[m* n-m+i]);}
	}
	}else if(!strcmp(type,"float")){
		//mexPrintf("float\n");
		for (i=0;i<m;i++){
			for (j=0;j<n-1;j++){
				if (mxIsNaN(ptrFloat[j*m+i])){
					fprintf(fp, "%s%s",char_nan,str);
				}else if (mxIsInf(ptrFloat[j*m+i])){
						fprintf(fp, "%s%s",char_inf,str);
				}else{
					fprintf(fp, "%.*f%s",*precision,(float)ptrFloat[j* m+i],str);
				}
			}
			if (mxIsNaN(ptrFloat[m* n-m+i])){
					fprintf(fp, "%s\n",char_nan,str);
				}else if (mxIsInf(ptrFloat[m* n-m+i])){
					fprintf(fp, "%s\n",char_inf,str);
				}else{
					fprintf(fp, "%.*f\n",*precision,(float)ptrFloat[m* n-m+i]);}
		}
	}else if(!strcmp(type,"long")){
		//mexPrintf("long\n");
		for (i=0;i<m;i++){
			for (j=0;j<n-1;j++){
				if (mxIsNaN(ptrLong[j*m+i])){
					fprintf(fp, "%s%s",char_nan,str);
				}else if (mxIsInf(ptrLong[j*m+i])){
						fprintf(fp, "%s%s",char_inf,str);
				}else{
					fprintf(fp, "%.*d%s",*precision,ptrLong[j* m+i],str);
				}
			}
			if (mxIsNaN(ptrLong[m* n-m+i])){
					fprintf(fp, "%s\n",char_nan,str);
				}else if (mxIsInf(ptrLong[m* n-m+i])){
						fprintf(fp, "%s\n",char_inf,str);
				}else{
					fprintf(fp, "%.*d\n",*precision,ptrLong[m* n-m+i]);}
		}
	}
} 
