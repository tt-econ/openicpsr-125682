function is_consistent = IsConsistent(obj, param, xtol)
%
% Determines whether parameters satisfy constraints
%
% INPUTS
%
%    - param: Parameter vector to check against constraints.
%
%    - xtol: A scalar controlling the tolerance of equality tests.
%
% OUTPUTS
%
%    - is_consistent: Logical scalar indicating whether or not parameters satisfy constraints.
%
if nargin==2
    xtol = 10^-4;
end
is_consistent = 1;
if ~isempty(obj.A)
    is_consistent =  is_consistent && check_almost_true( obj.A * param, obj.b, 'leq', xtol );
end
if ~isempty(obj.Aeq)
    is_consistent =  is_consistent && check_almost_true( obj.Aeq * param, obj.beq, 'eq', xtol );
end
if ~isempty(obj.lb)
    is_consistent =  is_consistent && check_almost_true( obj.lb', param, 'leq', xtol );
end
if ~isempty(obj.ub)
    is_consistent =  is_consistent && check_almost_true( param, obj.ub', 'leq', xtol );
end
if ~isempty(obj.nonlcon)
    [c, ceq] = obj.nonlcon(param);
    if ~isempty(c)
        is_consistent =  is_consistent && check_almost_true( c, 0, 'leq', xtol );
    end
    if ~isempty(ceq)
        is_consistent =  is_consistent && check_almost_true( ceq, 0, 'eq', xtol );
    end
end
end

function result = check_almost_true(element1, element2, constr, xtol)
    result = 0;
    if isequal(constr, 'leq')
        result = all( sign(element1 - element2) .* abs(element1 - element2) <= xtol );
    elseif isequal(constr, 'eq')
        result = all( abs(element1 - element2) <= xtol );
    end
end