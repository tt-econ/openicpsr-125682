function jacobian_of_active_constraints = JacobianOfActiveConstraints( obj )
% 
% Outputs the Jacobian of the active constraints with
% respect to the parameters.
%
% OUTPUTS
%
%    - jacobian_of_active_constraints: Matrix with rows corresponding to Jacobians of the 
%      active constraints with repect to the parameters.
%

constraints = fieldnames(obj.ActiveConstraints);
jacobian_of_active_constraints = [];
for i = 1:numel(constraints)
jacobian_of_active_constraints = ...
    [jacobian_of_active_constraints;...
    obj.constr_jacobian.(constraints{i})(obj.ActiveConstraints.(constraints{i}),:)];
end

end

