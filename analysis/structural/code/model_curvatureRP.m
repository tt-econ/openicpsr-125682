classdef model_curvatureRP< MleModel
%
%

properties
    paramlist = {'lnpsi', 'transformed_nu', 'lnsigma', 'lngl', 'theta'};
    lhslist = 'final_trip';
    rhslist = {};
    default_startparam = [];
    main_startparam = [-3.72689; 1.11384; -0.63263; 0.98401; 0.820080];
    controls_startparam = [-0.03479; -0.00761; -0.14350;  0.05743; -0.01227; 0.11214;  0.11899;  0.11289;  0.10270;  0.10249;  0.15665; -0.30134; -0.30184; -0.28523; -0.22108; -0.16725; -0.01810;  0.20299;  0.54196; 0.35983; -0.00227;  0.24487; -0.09604; -0.17029; -0.22496; -0.16279; 0.26102;  0.29508;  0.45144;  0.50781;  0.30327;  0.00520; -0.23380; -0.87642];
    indiv_unobs_list = {};
    group_unobs_list = {};
    error_list = {'epsilon'};
    error_distributions = struct('epsilon', @(P)norminv(P,0,1));
    error_dimensions = struct('epsilon', 1);
    dparamlist = {'nu', 'gl', 'sigma'};
    controls = {};
    psis = {};
    include_constant = true;
end

methods
    function obj = model_curvatureRP(varargin)
        obj = obj@MleModel(varargin{:});
        obj.paramlist = obj.AddCoefficients(obj.paramlist, [obj.controls], obj.include_constant);
        obj.default_startparam = zeros(obj.nparam, 1);
        obj.default_startparam(1:length(obj.main_startparam)) = obj.main_startparam;
        obj.default_startparam(length(obj.main_startparam) + 1 : length(obj.main_startparam) + length(obj.controls_startparam)) = obj.controls_startparam;
    end
end

methods (Access = protected)
    function clik = ComputeConditionalLikelihoodVector(obj, param, data)
        cdf = prob_stop(obj, param, data);

        clik = cdf .^ (data.var.(obj.lhslist) == 1) .* ...
            (1 - cdf) .^ (data.var.(obj.lhslist) == 0);
    end

    function lhs = ComputeOutcomes(obj, param, data)
        utility_difference = compute_utility_difference(obj, param, data);
        if (~isempty(obj.controls))
            xb = obj.Xbeta(obj.controls, data, param, obj.include_constant);
            utility_difference = utility_difference + xb;
        end
        eps = data.var.epsilon * exp(param(obj.indices.lnsigma));
        lhs.(obj.lhslist) = utility_difference > eps;
    end

    function dparam = DerivedParam(obj, param, ~, dparamname)
        switch dparamname
            case 'sigma'
                dparam = exp(param(obj.indices.lnsigma));
            case 'nu'
                dparam = exp(param(obj.indices.transformed_nu)) - 1;
            case 'gl'
                dparam = exp(param(obj.indices.lngl));
            case 'theta'
                dparam = param(obj.indices.theta);
        end
    end
end

methods (Access = public)
    function cdf = prob_stop(obj, param, data)
        utility_difference = compute_utility_difference(obj, param, data);
        if (~isempty(obj.controls))
            if obj.include_constant
                control_param = param(length(obj.main_startparam) + 1 : length(obj.main_startparam) + length(obj.controls));
                xb = data.controls * control_param + param(end);
            end
        utility_difference = utility_difference + xb;
        end
        cdf = normcdf(utility_difference, 0, ...
                      exp(param(obj.indices.lnsigma)));
    end

    function utility_difference = compute_utility_difference(obj, param, data)
        nu = DerivedParam(obj, param, 0, 'nu');
        gl = DerivedParam(obj, param, 0, 'gl');

        psi = exp(param(obj.indices.lnpsi));

        r_income = compute_r_income(obj, param, data);
        r_duration = data.var.r_duration;

        a1 = (data.var.exp_cum_income < r_income) .* (-(abs(data.var.exp_cum_income - r_income)).^.88) ...
           - ((data.var.cum_income < r_income) .* (-(abs(data.var.cum_income - r_income)).^.88));

        a2 = (data.var.exp_cum_income > r_income) .* ((abs(data.var.exp_cum_income - r_income))).^.88 ...
           - ((data.var.cum_income > r_income) .* ((abs(data.var.cum_income - r_income)).^.88));

        b1 = ((data.var.cum_total_duration + data.var.exp_duration) > r_duration ) .* ...
            ((abs((data.var.cum_total_duration + data.var.exp_duration) .^ (nu + 1) - r_duration .^ (nu + 1)))).^.88 ...
           - (data.var.cum_total_duration > r_duration) .* ...
            ((abs(data.var.cum_total_duration .^ (nu + 1) - r_duration .^ (nu + 1)))).^.88;

        b2 = ((data.var.cum_total_duration + data.var.exp_duration) < r_duration ) .* ...
            (-(abs((data.var.cum_total_duration + data.var.exp_duration) .^ (nu + 1) - r_duration .^ (nu + 1))).^.88) ...
           - (data.var.cum_total_duration < r_duration ) .* ...
            (-(abs(data.var.cum_total_duration .^ (nu + 1) - r_duration .^ (nu + 1))).^.88);

        utility_difference = - ( gl * a1 + a2 - psi / (nu + 1) .* b1 ...
            - psi / (nu + 1) .* b2 );
    end

    function r_income = compute_r_income(obj, param, data)
        theta = param(obj.indices.theta);
        weight = max(0, 1 - theta .^ data.w);
        r_income = data.var.r_income + sum(data.del .* weight, 2);
    end

end

end
