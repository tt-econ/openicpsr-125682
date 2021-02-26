function is_constrained = IsConstrained(obj, paramlist)
%
% Outputs logical value for whether any parameter in paramlist is involved in 
% an active constraint.
%
% INPUTS
%
%    - paramlist: Cell array list of parameter names.  Subset of obj.paramlist.
%
% OUTPUTS
%
%    - is_constrained: Logical value indicating whether any parameter in 
%      paramlist is involved in an active constraint.
%

param_indices = zeros(1, length(paramlist));

if ~isempty(obj.active_jacobian)
	for i = 1:length(paramlist)
		param_indices(1, i) = obj.model.indices.(paramlist{i});
	end
	is_constrained = any(any(obj.active_jacobian(:,param_indices)));
else
	is_constrained = 0;
end

end
