function [dmparam, dmvcov] = DeltaMethod(obj, matrix, function_of_params, vcov, xtol)
%
% Computes the point estimate and variance-covariance matrix of linear
% and nonlinear transformations of variables.
% See Greene (2012) Thm D.21A (p. 1082) for expressions and notation
%
% INPUTS
%    - matrix: A matrix representing a linear function of parameters.
%
%    - function_of_params: A (possibly vector-valued) function of the parameters.
%
%    - vcov: A matrix containing a variance-covariance matrix of the
%    parameters.
%
%    - xtol: A scalar controlling the step size of numerical derivatives.
% 
% OUTPUTS
%
%    - dmparam: A vector of point estimates of the functions of the parameters.
%
%    - dmvcov: The variance-covariance matrix of the functions of the parameters.
%

if nargin==3
    vcov = obj.vcov;
end
if nargin<=4
    xtol = 10^-4;
end
if isempty(function_of_params)
    dmparam = matrix*obj.param;
elseif isempty(matrix)
    dmparam = function_of_params(obj.param);
else
    dmparam = [matrix*obj.param; function_of_params(obj.param)];
end
C = [matrix; NumJacob( function_of_params, obj.param', xtol)];
Sigma = vcov;
if isempty(Sigma)
    dmvcov = [];
else
    dmvcov = C*Sigma*C';
end

end 

