classdef MleConstraints
%
% MleConstraints defines equality and inequality constraints on parameters.
%   The format of the constraints follows the format expected by the Matlab
%   interface to Knitro, knitromatlab(). See 'help knitromatlab' for details.
%
% The general problem solved by MleModel.Estimate() is
%
%    max SumLogLik(x)  subject to:  A*x  <= b, Aeq*x  = beq (linear constraints)
%     x                             C(x) <= 0, Ceq(x) = 0   (nonlinear constraints)
%                                   lb <= x <= ub           (bounds)
%
%  s.t.
%    c(x) <= 0
%    ceq(x) = 0
%
% The property nonlcon is a handle to the function that computes the nonlinear
%   inequality constraints c(x)? 0 and the nonlinear equality constraints ceq(x) = 0.
%   nonlcon accepts a parameter vector x and returns the two vectors c and ceq.
%   c contains the nonlinear inequalities evaluated at x, and ceq contains the
%   nonlinear equalities evaluated at x. The function nonlcon can be specified
%   as a function handle x = ktrlink(@myfun,x0,A,b,Aeq,beq,lb,ub,@mycon)
%
%   where mycon is a MATLAB function such as
%   function [c,ceq] = mycon(x)
%     c = ...     % Compute nonlinear inequalities at x.
%     ceq = ...   % Compute nonlinear equalities at x.
%
%   If you can compute the gradients of the constraints and the GradConstr
%   option is 'on', as set by options = optimset('GradConstr','on'), then nonlcon
%   must also return GC, the gradient of c(x), and GCeq, the gradient of ceq(x),
%   in the third and fourth output arguments respectively.
%


properties
    A           % Matrix defining linear inequality constraints (A*x <= b)
    b           % Vector defining linear inequality constraints (A*x <= b)
    Aeq         % Matrix defining linear equality constraints (Aeq*x = beq)
    beq         % Vector defining linear equality constraints (Aeq*x = beq)
    lb          % Lower bound on parameter vector
    ub          % Upper bound on parameter vector
    nonlcon     % Function defining non-linear constraints C() and Ceq()
    extendedFeatures % Structure defining complementarity constraints
    default_jac_tol = 10^-4  % Default numerical precision for evaluating numerical Jacobian
    paramlist   % Cell array of parameter names; this defines the parameter vector
end

properties (Dependent = true, SetAccess = protected)
    nparam      % Number of parameters
    indices     % Struct giving the index of each parameter
end

methods
    function obj = MleConstraints(A, b, Aeq, beq, lb, ub, nonlcon, ...
                                  extendedFeatures, paramlist)
    % Create a new MleConstraints object.
        if nargin > 0
            obj.A = A;
        end
        if nargin > 1
            obj.b = b;
        end
        if nargin > 2
            obj.Aeq = Aeq;
        end
        if nargin > 3
            obj.beq = beq;
        end
        if nargin > 4
            obj.lb = lb;
        end
        if nargin > 5
            obj.ub = ub;
        end
        if nargin > 6
            obj.nonlcon = nonlcon;
        end
        if nargin > 7
            obj.extendedFeatures = extendedFeatures;
        end
        if nargin > 8
            obj.paramlist = paramlist;
        end
    end

    function c = NonlinearInequalityConstraints(obj, param)
        [c, ~] = obj.nonlcon(param);
    end

    function ceq = NonlinearEqualityConstraints(obj, param)
        [~, ceq] = obj.nonlcon(param);
    end

    function nparam = get.nparam(obj)
        nparam = length(obj.paramlist);
    end

    function indices = get.indices(obj)
        [~, indices] = parse_name_list(obj.paramlist);
    end

    J = JacobianOfConstraints(obj, param, xtol);
    is_consistent = IsConsistent(obj, param, xtol);
    constr = SetUpperBound(obj, constr_paramlist, bounds);
    constr = SetLowerBound(obj, constr_paramlist, bounds);
    constr = SetFixedBound(obj, constr_paramlist, bounds);
    constr = RemoveBound(obj, constr_paramlist);
end

end

