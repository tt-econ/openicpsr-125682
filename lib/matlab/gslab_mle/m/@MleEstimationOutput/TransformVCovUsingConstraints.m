function vcov_transformed = TransformVCovUsingConstraints(active_jacobian, information)
% Computes VCov accounting for all active constraints
% See Schoenberg 1997 for notation and expressions
%
% INPUTS
%
%    - active_jacobian: Matrix with rows corresponding to Jacobians of the 
%      active constraints with repect to the parameters.
%
%    - information: Hessian matrix at estimated parameters.
%
% OUTPUTS
%
%    - vcov_transformed: Variance-covariance matrix adjusted for active constraints.
%

% Hessian
Sigma = information;
% Jacobian of active constraints
Gdot = active_jacobian;
% Orthonormal basis of null space of Gdot
Xi = null(Gdot);
% Variance-covariance matrix of parameters
if isempty(Sigma)
    Omega = [];
elseif isempty(Xi)
    Omega = Sigma^(-1);
else
    Omega = Xi*(Xi'*Sigma*Xi)^(-1)*Xi';
end
vcov_transformed = Omega;

end
