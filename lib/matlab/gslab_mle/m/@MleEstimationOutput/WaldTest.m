function wald_test = WaldTest(obj, matrix, function_of_params, q, xtol)
%
% Computes Wald Statistic for linear and nonlinear hypotheses about parameters.
% See Greene (2012) Thm 14.6 (p. 528) for expressions and notation.
% See Moore (1977) and Andrews (1987) for discussion of generalized Wald test
% in the case of near-singular variance matrices. 
%
% INPUTS
%
%    - matrix: A matrix representing a linear function of parameters.
%
%    - function_of_params: A (possibly vector-valued) function of the parameters.
%
%    - q: A vector set equal to the function of parameters in the hypothesis being tested.
%
%    - xtol: A scalar controlling the step size of numerical derivatives for delta_method.
%
% OUTPUTS
%
%    - wald_test.wald_statistic:  Value of wald statisic at estimated parameters.
%
%    - wald_test.dof: Degrees of freedom used to calculate wald statistic p value.
%
%    - wald_test.pvalue: P value of wald statistic at estimated parameters from Chi squared distribution.
%

if nargin==4
    xtol = 10^-4;
end
    [c, asy_var_c] = DeltaMethod(obj, matrix, function_of_params, obj.vcov, xtol);
    wald_test.wald_statistic = (c - q)'*(generalized_inverse(asy_var_c))*(c - q);
    wald_test.dof = rank(asy_var_c);
    wald_test.pvalue = 1 - chi2cdf(wald_test.wald_statistic, wald_test.dof);
end

%if variance matrix is near-singular, compute generalized inverse
%using Moore-Penrose method.
function [ginv] = generalized_inverse(matrix)
    if (abs(rcond(matrix) - eps) <= eps) 
        ginv = pinv(matrix);
    else
        ginv = matrix^(-1);
    end
end