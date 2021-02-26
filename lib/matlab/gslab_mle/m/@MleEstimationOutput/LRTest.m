function lr_test = LRTest(obj, unrestricted, number_of_restrictions, xtol)
%
% Computes Likelihood Ratio for a set of restrictions.
% See Greene (2012) Thm 14.5 (p. 527) for expressions and notation.
%
% INPUTS
%
%    - unrestricted: Unrestricted model to test against.
%
%    - number_of_restrictions: Number of restrictions imposed in restricted model relative to unrestricted.
%
%    - xtol: A scalar controlling the tolerance of equality tests. 
%
% OUTPUTS
%
%    - lr_test.log_likelihood_ratio: Log likelihood ratio. Exponentiate to retrieve likelihood ratio.
%
%    - lr_test.lr_statistic: Likelihood ratio statistic.
%
%    - lr_test.dof: Degrees of freedom of test.
%
%    - lr_test.pvalue: P-value of test.
%
if nargin < 4;
	xtol = 10^-4;
end
if nargin == 2;
	number_of_restrictions = rank(obj.active_jacobian) - rank(unrestricted.active_jacobian);
end
checks(obj, unrestricted, xtol);
lr_test.log_likelihood_ratio = unrestricted.fval - obj.fval;
lr_test.lr_statistic = 2*(obj.fval-unrestricted.fval);
lr_test.dof = number_of_restrictions;
lr_test.pvalue = 1 - chi2cdf(lr_test.lr_statistic, lr_test.dof);
end

function checks(restricted, unrestricted, xtol)
    % Check restricted model nested in unrestricted
    if ~unrestricted.constr.IsConsistent(restricted.param, xtol)
        warning('Restricted model is not nested.');
    end
    
    % Check likelihood ratio is between zero and one
    if unrestricted.fval - restricted.fval >= 0
        warning('Likelihood ratio is not between zero and one.');
    end
end