classdef model_fixedRP< MleModel
%
%

properties
    paramlist = {'lnpsi', 'transformed_nu', 'lnsigma', 'lngl'};
    lhslist = 'final_trip';
    rhslist = {};
    default_startparam = [];
    main_startparam = [-4.28828; 0.98428; -1.51162; 0.38008];
    controls_startparam = [-0.00278;  0.03283; -0.01971;  0.06559; -0.00522; 0.05329;  0.05765;  0.05331;  0.04801;  0.04337;  0.07505; -0.13124; -0.13552; -0.13398; -0.11353; -0.09349; -0.02703;  0.07492;  0.22517; 0.14492; -0.01003;  0.11497; -0.04489; -0.07136; -0.09436; -0.07056; 0.11932;  0.12429;  0.18747;  0.19460;  0.10128; -0.01016; -0.10493; -0.37065];
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
    function obj = model_fixedRP(varargin)
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

        r_income = data.var.r_income_fixed;
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

end

end
