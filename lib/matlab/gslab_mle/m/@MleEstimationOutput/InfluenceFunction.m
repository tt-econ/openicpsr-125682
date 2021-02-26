function influence_function = InfluenceFunction(obj)
%
% Computes a matrix with the influence function for each observation with respect to 
% each parameter as an output
%
% INPUTS
%    - MleEstimationOutput object
% 
% OUTPUTS
%    - influence_function: nobs (or ngroups) x nparam matrix
%

assert(obj.estopts.compute_hessian && obj.estopts.compute_jacobian)

influence_function = -(size(obj.jacobian, 1) * inv(obj.hessian) * obj.jacobian')';

end 

