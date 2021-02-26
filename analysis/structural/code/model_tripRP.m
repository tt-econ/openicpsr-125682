classdef model_tripRP< MleModel
%
%

properties
    paramlist = {'lnpsi', 'transformed_nu', 'lnsigma', 'lngl'};
    lhslist = 'final_trip';
    rhslist = {};
    default_startparam = [];
    main_startparam = [-3.189925; 0.998500; -0.240175; 1.667100];
    controls_startparam = [-0.205475; -0.047575; -0.249075;  0.069125; 0.025600;  0.178300;  0.174250;  0.157675;  0.160750;  0.176200;  0.322350; -0.576075; -0.572575; -0.547775; -0.455750; -0.338800; -0.063275; 0.344300;  0.881700;  0.604775;  0.017800;  0.481325; -0.149750; -0.284700; -0.388025; -0.278225;  0.495025;  0.494725;  0.715475; 0.651375;  0.297350; -0.083775; -0.480025; -1.248975];
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
    function obj = model_tripRP(varargin)
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

        r_income = data.var.r_income_trip;
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
