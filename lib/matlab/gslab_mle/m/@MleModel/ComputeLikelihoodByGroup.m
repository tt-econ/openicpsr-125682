function grouplik = ComputeLikelihoodByGroup(obj, param, data, nodes, weights)
%
% Compute likelihood by group, integrating unobservables numerically
%
    if obj.numerical_integral
        unobs = obj.TransformUnobservables(param, data, nodes.values);
        data = data.AddData(unobs);
    end

    condlik = obj.ComputeConditionalLikelihoodVector(param, data);

    if ~isempty(data.groupvar) && (data.ngroups < data.nobs)
        grouplik = prodwithin(condlik, data.groupvar);
    else
        grouplik = condlik;
    end

    if obj.numerical_integral
        grouplik = sumwithin(grouplik.*weights.wgt, weights.group);
    end

    % Handle case where negative weights lead to grouplik <= 0
    grouplik(grouplik<=0)=eps;
end

