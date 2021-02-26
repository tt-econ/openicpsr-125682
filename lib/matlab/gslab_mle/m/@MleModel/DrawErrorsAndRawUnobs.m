function [error, raw_unobs] = DrawErrorsAndRawUnobs(obj, data, simopts)
%
% DrawErrorsAndRawUnobs draws unobs and error vectors for a given model.
%

    if ~isempty(simopts) && ~isempty(simopts.seed)
        rng(simopts.seed)
    else
        rng('default')
    end

    error = draw_errors(obj, data);
    raw_unobs = draw_raw_unobs(obj, data);
end

function draws = draw_errors(obj, data)
    draws = struct();
    for i = 1:length(obj.error_list)
        var_name = obj.error_list{i};
        var_dist_fn = obj.error_distributions.(var_name);
        draws.(var_name) = feval(var_dist_fn, rand([data.nobs obj.error_dimensions.(var_name)]));
    end
end

function draws = draw_raw_unobs(obj, data)
    draws = struct();
    for i = 1:length(obj.group_unobs_list)
        groupdraws = randn(data.ngroups,1);
        draws.(obj.group_unobs_list{i}) = groupdraws(data.groupvar);
    end
    for i = 1:length(obj.indiv_unobs_list)
        draws.(obj.indiv_unobs_list{i}) = randn(data.nobs,1);
    end
end
