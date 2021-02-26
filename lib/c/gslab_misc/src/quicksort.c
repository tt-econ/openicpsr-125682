// Adapted by Ernest on 2/20/2012 from http://alienryderflex.com/quicksort/

//Sorts a two-dimensional array of pointers "arr" into ascending order using Quicksort, while making the corresponding
//  rearrangement of the two-dimensional array of pointers "brr". "struc" is a auxiliary pointer
//  to any additional input that needs to be fed into the comparision function.
//  If "brr" points to NULL, then this input is ignored.
#include <stdio.h>

#define SWAP(a,b) temp=(a);(a)=(b);(b)=temp;
  
void quicksort(double ***arr, double ***brr, int elements, 
               double (*cmp_ptr)(const void *, const void *, const void*),
               void *struc) {
    #define  MAX_LEVELS  300
    double **piv, **piv_val;
    int  beg[MAX_LEVELS], end[MAX_LEVELS], i, L, R, temp, sorted=1;
    
    for(i=1;i<elements;i++){
        if((*cmp_ptr)(arr[i-1],arr[i],struc)>0){
            sorted = 0;
        }
    }   
    if(sorted==0){
        i=0;    
        beg[0]=0; end[0]=elements;
        while(i>=0){
            L=beg[i]; 
            R=end[i]-1;
            if(L<R){
                piv = arr[L];
                if (brr!=NULL){
                    piv_val = brr[L];
                }
                while(L<R){
                    while((*cmp_ptr)(arr[R],piv,struc)>=0 && L<R) R--; 
                    if(L<R){
                        arr[L]=arr[R];
                        if (brr!=NULL){
                            brr[L++] = brr[R];
                        }
                    }
                    while((*cmp_ptr)(arr[L],piv,struc)<=0 && L<R) L++; 
                    if(L<R){
                        arr[R]=arr[L];
                        if (brr!=NULL){
                            brr[R--]=brr[L];
                        }
                    }
                }
                arr[L]=piv;
                if (brr!=NULL){
                    brr[L]=piv_val;
                }
                beg[i+1]=L+1; 
                end[i+1]=end[i]; 
                end[i++]=L;
                if(end[i]-beg[i]>end[i-1]-beg[i-1]){
                    SWAP(beg[i],beg[i-1]);
                    SWAP(end[i],end[i-1]);
                }
            }
            else{
                i--; 
            }
        }
    }
}
