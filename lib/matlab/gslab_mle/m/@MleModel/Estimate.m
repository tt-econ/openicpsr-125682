function est = Estimate(obj, data, estopts)
%
% Estimates an MleModel by maximum likelihood with numerical integration.
%
% INPUTS
%   - data: An MleData object.
%   - estopts: An MleEstimationOptions object.
%
% OUTPUTS
%   - est: An MleEstimationOutput object.
%
    if nargin == 2
        estopts = MleEstimationOptions();
    end
    if estopts.quiet == 1
        estopts.ktr = optimset(estopts.ktr, 'Display', 'off');
    end
    estopts.startparam = set_startparam(obj, estopts);
    [nodes, weights, data_rep] = obj.ComputeNodesAndWeights(data, estopts.quadacc);

    if length(estopts.constr.lb) < length(estopts.startparam)
        lb = -Inf * ones(length(estopts.startparam) - length(estopts.constr.lb), 1);
        if size(estopts.constr.lb, 2) == 1
            estopts.constr.lb = [estopts.constr.lb; lb];
        else
            estopts.constr.lb = [estopts.constr.lb lb];
        end
    end

    if length(estopts.constr.ub) < length(estopts.startparam)
        ub = Inf * ones(length(estopts.startparam) - length(estopts.constr.ub), 1);
        if size(estopts.constr.ub, 2) == 1
            estopts.constr.ub = [estopts.constr.ub; ub];
        else
            estopts.constr.ub = [estopts.constr.ub ub];
        end
    end

    if ~isempty(estopts.first_step_param)
        estopts.constr.paramlist = obj.paramlist;
        estopts.constr = ...
            estopts.constr.SetFixedBound(estopts.first_step_paramlist, estopts.first_step_param);
    end

    % Main call to solver
    [slvr.paramhat, slvr.fval, slvr.exitflag, slvr.output, slvr.lambda] = ...
        fmincon(@(param)-sum_log_lik(obj, param, data_rep, nodes, weights), estopts.startparam, ...
        estopts.constr.A, estopts.constr.b, estopts.constr.Aeq, estopts.constr.beq, ...
        estopts.constr.lb, estopts.constr.ub, estopts.constr.nonlcon, ...
        estopts.ktr);

    if estopts.quiet == 0
        slvr.hessian = [];
        slvr.jacobian = [];
        est = MleEstimationOutput(slvr, estopts, obj, data);
        est.Play;
    end
    [slvr.hessian, slvr.jacobian] = deal([], []);
    if estopts.compute_hessian == 1
        slvr.hessian = compute_hessian(obj, slvr.paramhat, data, estopts);
    end
    if estopts.compute_jacobian == 1
        slvr.jacobian = compute_jacobian(obj, slvr.paramhat, data, estopts);
    end
    est = MleEstimationOutput(slvr, estopts, obj, data);
    if estopts.quiet == 0
        est.Play;
    end
end

function startparam = set_startparam(obj, estopts)
    if isempty(estopts.startparam)
        startparam = obj.default_startparam;
    else
        startparam = estopts.startparam;
    end
    assert( obj.IsValidParameterVector(startparam) );
end

function ll = log_lik(obj, param, data, nodes, weights)
    ll = log(obj.ComputeLikelihoodByGroup(param, data, nodes, weights));
end

function sll = sum_log_lik(obj, param, data, nodes, weights)
    sll = sum(log_lik(obj, param, data, nodes, weights));
end

function [hessian] = compute_hessian(obj, paramhat, data, estopts)
    [nodes, weights, data_rep] = obj.ComputeNodesAndWeights(data, estopts.quadacc_deriv);
    hessian = NumHess(@(param)-sum_log_lik(obj, param, data_rep, nodes, weights),...
        paramhat, estopts.hesstol);
end

function [jacobian] = compute_jacobian(obj, paramhat, data, estopts)
    [nodes, weights, data_rep] = obj.ComputeNodesAndWeights(data, estopts.quadacc_deriv);
    jacobian = NumJacob(@(param)-log_lik(obj, param, data_rep, nodes, weights),...
        paramhat, estopts.hesstol);
end
