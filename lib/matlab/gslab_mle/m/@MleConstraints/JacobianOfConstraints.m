function J = JacobianOfConstraints(obj, param, xtol)
%
% Returns the jacobian of constraints
%
% INPUTS
%
%    - param: Parameter vector at which to evaluate jacobian.
%
%    - xtol: A scalar controlling the step size of numerical derivatives.
%
% OUTPUTS
%
%    - J: Struct containing jacobians of the different constraints.
%
if nargin==2
    xtol = obj.default_jac_tol;
end
J = struct('lower',[],'upper',[],'ineqlin',[],'eqlin',[], ...
           'ineqnonlin',[],'eqnonlin',[]);
J.lower = eye(length(obj.lb), length(obj.lb));
J.upper = eye(length(obj.ub), length(obj.ub));
J.ineqlin = obj.A;
J.eqlin = obj.Aeq;
if ~isempty(obj.nonlcon)
    if ~isempty(obj.NonlinearInequalityConstraints(param'))
        J.ineqnonlin = NumJacob(@obj.NonlinearInequalityConstraints, param', xtol);
    end
    if ~isempty(obj.NonlinearEqualityConstraints(param'))
        J.eqnonlin = NumJacob(@obj.NonlinearEqualityConstraints, param', xtol);
    end
end