function active_constraints = ActiveConstraints( obj )
%
% Outputs logical arrays indexing active constraints.
% An active constraint is either a constraint with a nonzero lagrange multipler or
% a fixed bound constraint (lb=ub).
%
% OUTPUTS
%
%    - active_constraints: A logical array indicating which constraints are active.
%

constraints = fieldnames(obj.lambda);
for i = 1:numel(constraints)
    active_constraints.(constraints{i}) = obj.lambda.(constraints{i})~=0;
    if (isequal(constraints{i},'lower') || isequal(constraints{i},'upper')) ...
            && ~isempty(obj.constr.lb) && ~isempty(obj.constr.ub)
        
        lb = obj.constr.lb;
        ub = obj.constr.ub;
        if (size(lb, 1)==1 && size(active_constraints.(constraints{i}), 2)==1) ...
               || (size(lb, 2)==1 && size(active_constraints.(constraints{i}), 1)==1)
           lb = lb';
           ub = ub';
        end
        
        active_constraints.(constraints{i}) = ...
            active_constraints.(constraints{i}) | (lb==ub);
    end
end

end

