classdef MleEstimationOutput < ModelEstimationOutput
%
% MleEstimationOutput holds estimates of the MLE model.
%

properties
    hessian     % Numerical hessian at estimated parameters
    jacobian
    constr      % Constraints (MleConstraints object)
    constr_jacobian %Numerican jacobian of the constraints at estimated parameters
    const       % Constants used in estimation
    play_controls % Whether to show the controls in Play
end

properties (Dependent)
    vcov        % Variance-covariance matrix of parameters
    active_jacobian %Jacobian of active constraints
    vcov_twostep %Variance-covariance matrix of parameters adjusting for two-step estimation
    se_twostep
    vcov_opg    % OPG variance-covariance matrix
    se_opg
    vcov_sandwich % Sandwich variance-covariance matrix
    se_sandwich
    dparam       % Vector of derived parameters
    dvcov        % Variance-covariance matrix of derived parameters
    dse          % Standard error of derived parameters
    dvcov_twostep
    dse_twostep
end

methods
    function obj = MleEstimationOutput(slvr, estopts, model, data)
        obj = obj@ModelEstimationOutput(slvr, estopts, model, data);
        obj.hessian = slvr.hessian;
        obj.jacobian = slvr.jacobian;
        obj.constr = estopts.constr;
        obj.constr_jacobian = obj.constr.JacobianOfConstraints(obj.param);
        obj.const = data.const;
        obj.play_controls = estopts.play_controls;
    end

    function vcov = get.vcov(obj)
        if isempty(obj.hessian)
            vcov = [];
        else
            vcov = obj.TransformVCovUsingConstraints(obj.active_jacobian, obj.hessian);
        end
    end

    function vcov_twostep = get.vcov_twostep(obj)
        if isempty(obj.estopts.first_step_vcov)
            vcov_twostep = [];
        else
            vcov_twostep = TwoStepVCov(obj, obj.estopts.first_step_vcov, ...
                                       obj.estopts.first_step_paramlist);
        end
    end

    function se_twostep = get.se_twostep(obj)
        se_twostep = sqrt(diag(obj.vcov_twostep));
    end

    function vcov_opg = get.vcov_opg(obj)
        % See Greene (5th Ed, 2002, Econometric Analysis, p. 481)
        vcov_opg = obj.TransformVCovUsingConstraints(obj.active_jacobian, ...
            obj.jacobian' * obj.jacobian);
    end

    function se_opg = get.se_opg(obj)
        se_opg = sqrt(diag(obj.vcov_opg));
    end

    function vcov_sandwich = get.vcov_sandwich(obj)
        % See Train (2nd Ed, 2009, Discrete Choice Methods with Simulation, p. 201)
        vcov_sandwich = obj.TransformVCovUsingConstraints(obj.active_jacobian,...
            ((obj.hessian)^(-1) * (obj.jacobian' * obj.jacobian) * (obj.hessian)^(-1))^(-1));
    end

    function se_sandwich = get.se_sandwich(obj)
        se_sandwich = sqrt(diag(obj.vcov_sandwich));
    end

    function active_jacobian = get.active_jacobian(obj)
        active_jacobian = obj.JacobianOfActiveConstraints;
    end

    function dparam = get.dparam(obj)
        dparam = obj.model.GetDerivedParam(obj.param, obj.const);
    end

    function dvcov = get.dvcov(obj)
        if isempty(obj.vcov)
            dvcov = [];
        else
            [~, dvcov] = obj.DeltaMethod([], ...
                @(param)obj.model.GetDerivedParam(param, obj.const));
        end
    end

    function dse = get.dse(obj)
        dse = sqrt(diag(obj.dvcov));
    end

    function dvcov_twostep = get.dvcov_twostep(obj)
        if isempty(obj.vcov_twostep)
            dvcov_twostep = [];
        else
            [~, dvcov_twostep] = obj.DeltaMethod([], ...
                @(param)obj.model.GetDerivedParam(param, obj.const),obj.vcov_twostep);
        end
    end

    function dse_twostep = get.dse_twostep(obj)
        dse_twostep = sqrt(diag(obj.dvcov_twostep));
    end

    function bool = IsValidEstimate(obj)
        bool = true;
        if ~isempty(obj.model)
            assert( isequal( length(obj.param), length(obj.model.paramlist) ));
            if ~isempty(obj.hessian)
                assert( isequal( length(obj.hessian), length(obj.model.paramlist) ));
                assert( isequal( size(obj.hessian, 1), size(obj.hessian, 2) ));
            end
        end
    end

    jacobian_of_active_constraints = JacobianOfActiveConstraints(obj)
    active_constraints = ActiveConstraints(obj)
    [dmparam, dmvcov] = DeltaMethod(obj, matrix, function_of_params, vcov, xtol)
    vcov_twostep = TwoStepVCov(obj, first_step_vcov, first_step_paramlist)
    wald_test = WaldTest(obj, matrix, function_of_params, q, xtol)
    lr_test = LRTest(obj, unrestricted, number_of_restrictions, xtol)
    is_constrained = IsConstrained(obj, paramlist)
    sparam = GetParamSubset(obj, subparamlist)
    svcov = GetVCovSubset(obj, subparamlist)
    phess = GetPartialHessian(obj, rowparamlist, colparamlist)
    est = SetLagrangianToZero(obj, paramlist)
    Play(obj, vcov, dvcov)
    [stats, dstats] = PlayStats(obj, vcov, dvcov)
    influence_function = InfluenceFunction(obj)
end

methods (Access = private)
    PlayFull(obj, vcov, dvcov, play_nparam)
    PlayPointEstimates(obj, play_nparam)
end

methods (Static, Access = private)
    vcov_transformed = TransformVCovUsingConstraints(active_jacobian, information)
end

end
