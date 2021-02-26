classdef model_adaptiveRP< MleModel
%
%

properties
    paramlist = {'lnpsi', 'transformed_nu', 'lnsigma', 'lngl', 'theta'};
    lhslist = 'final_trip';
    rhslist = {};
    default_startparam = [];
    main_startparam = [-2.320300; 0.583100; -1.000678; 0.913800; 0.843311];
    controls_startparam = [-0.013033;  0.024011; -0.063122;  0.078189; -0.006778;  0.075367;  0.078800;  0.077056;  0.070789;  0.073967; 0.111256; -0.193133; -0.203756; -0.198200; -0.152067; -0.111444; -0.003900; 0.146644;  0.380611;  0.252811;  0.004578;  0.177022; -0.053211; -0.097256; -0.137833; -0.103133;  0.188022;  0.203344;  0.317333; 0.356433;  0.210011;  0.001789; -0.157900;  0.163900;  0.160444; 0.150067;  0.192489;  0.326189;  0.433878;  0.437678;  0.373022; -0.631556];
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
    function obj = model_adaptiveRP(varargin)
        obj = obj@MleModel(varargin{:});
        obj.paramlist = obj.AddCoefficients(obj.paramlist, [obj.controls; obj.psis], obj.include_constant);
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

        psi_param = param(length(obj.main_startparam) + length(obj.controls) + 1 : end - 1);
        psi_xb = data.psis * psi_param;
        psi = exp(param(obj.indices.lnpsi) + psi_xb);

        r_income = compute_r_income(obj, param, data);
        r_duration = data.var.r_duration;

        a1 = (data.var.exp_cum_income < r_income) .* (-(abs(data.var.exp_cum_income - r_income))) ...
           - ((data.var.cum_income < r_income) .* (-(abs(data.var.cum_income - r_income))));

        a2 = (data.var.exp_cum_income > r_income) .* ((abs(data.var.exp_cum_income - r_income))) ...
           - ((data.var.cum_income > r_income) .* ((abs(data.var.cum_income - r_income))));

        b1 = ((data.var.cum_total_duration + data.var.exp_duration) > r_duration ) .* ...
            ((abs((data.var.cum_total_duration + data.var.exp_duration) .^ (nu + 1) - r_duration .^ (nu + 1)))) ...
           - (data.var.cum_total_duration > r_duration) .* ...
            ((abs(data.var.cum_total_duration .^ (nu + 1) - r_duration .^ (nu + 1))));

        b2 = ((data.var.cum_total_duration + data.var.exp_duration) < r_duration ) .* ...
            (-(abs((data.var.cum_total_duration + data.var.exp_duration) .^ (nu + 1) - r_duration .^ (nu + 1)))) ...
           - (data.var.cum_total_duration < r_duration ) .* ...
            (-(abs(data.var.cum_total_duration .^ (nu + 1) - r_duration .^ (nu + 1))));

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
