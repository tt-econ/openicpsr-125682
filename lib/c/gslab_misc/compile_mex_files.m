mex COMPFLAGS="$COMPFLAGS /MT" -outdir ./mex/private ./src/dlmwrite_c.c
mex COMPFLAGS="$COMPFLAGS /MT" -outdir ./mex/private ./src/nchoosek_c.c
mex COMPFLAGS="$COMPFLAGS /MT" -outdir ./mex/private ./src/factorial_c.c
mex COMPFLAGS="$COMPFLAGS /MT" -outdir ./mex ./src/mean_mat2D_c.c
mex COMPFLAGS="$COMPFLAGS /MT" -outdir ./mex ./src/transform_group.c
mex COMPFLAGS="$COMPFLAGS /MT" -outdir ./mex ./src/sumwithin.c ...
    ./src/quicksort.c ./src/operate_within.c
mex COMPFLAGS="$COMPFLAGS /MT" -outdir ./mex ./src/avgwithin.c ...
    ./src/quicksort.c ./src/operate_within.c
mex COMPFLAGS="$COMPFLAGS /MT" -outdir ./mex ./src/prodwithin.c ...
    ./src/quicksort.c ./src/operate_within.c
mex COMPFLAGS="$COMPFLAGS /MT" -outdir ./mex ./src/seqwithin.c ...
    ./src/quicksort.c
    
exit
