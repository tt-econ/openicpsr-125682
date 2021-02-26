function vcov_twostep = TwoStepVCov(obj, first_step_vcov, first_step_paramlist)
%
% Calculates two-step variance-covariance matrix
% See Greene (2012) Thm 14.8 (p. 537) for expressions and notation for
% V2_star.
% See /docs/ for derivation of off-diagonal elements of V_all.
%
% Notes:
% - Calculations assume independent samples (R=0)
% - Calculations use Hessian rather than product of gradients
% - Calculations ignore constraints in second step.
%
% INPUTS
%
%    - first_step_vcov: Variance-covariance matrix for the first step 
%      parameters (a subset of the second step parameters).
%
%    - first_step_paramlist: List of first_step model parameter names.
%
% OUTPUTS
%
%    - vcov_twostep: Adjusted variance-covariance matrix for the second step parameters.
%


if isempty(first_step_vcov)
    vcov_twostep = [];
    return;
end

assert( isequal(length( first_step_paramlist ), size(first_step_vcov, 1)) );
assert( isequal(length( first_step_paramlist ), size(first_step_vcov, 2)) );

second_step_paramlist = setdiff(obj.model.paramlist, first_step_paramlist);

V1 = first_step_vcov;
V2 = obj.GetVCovSubset(second_step_paramlist);
C = obj.GetPartialHessian(second_step_paramlist, first_step_paramlist);

V2_star = V2 + V2*(C*V1*C')*V2;

V_all = [V2_star, -V2*C*V1; -V1*C'*V2, V1];


[~,index] = ismember(obj.model.paramlist,...
    [second_step_paramlist first_step_paramlist ]);

vcov_twostep = V_all(index, index);

end
