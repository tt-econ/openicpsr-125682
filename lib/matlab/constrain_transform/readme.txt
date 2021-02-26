constrain_transform
readme.txt

NOTES
=========================================================
The functions constrain and unconstrain implement linear constraints for optimization.

The functions transform and untransform implement parameter-by-parameter transformations for optimization. For now, these functions are written to use log() or abs() as the transformation. The goal is to generalize them to allow any function.

The files test_*.m are utilities designed to test that the other functions are working properly.

The file transform.lyx contains the derivation for the formulas in transform.m and untransform.m.
