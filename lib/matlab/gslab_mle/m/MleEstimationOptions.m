classdef MleEstimationOptions < ModelEstimationOptions
%
% MleEstimationOptions defines options for the Estimate() method of
% MleModel.
%

properties
    quadacc                 = 3           % Accuracy of quadrature nodes for numerical integration in estimation.
    quadacc_deriv           = 4           % Accuracy of quadrature nodes for numerical integration in computing Hessians, gradients, etc.
    constr                  = MleConstraints() % An MleConstraints object.
    first_step_vcov         = []          % Variance-Covariance matrix for first estimation step
    first_step_paramlist    = {}          % List of parameter names from first estimation step
    first_step_param        = []          % A vector with the values of the first step parameters
    compute_hessian         = 1           % Compute Hessian at the estimated parameters  
    compute_jacobian        = 1           % Compute Jacobian of likelihood vector at the estimated parameters
    play_controls           = true       % If there are controls do we play them
end

methods
    function obj = MleEstimationOptions(varargin)
        if nargin > 0
            obj.ktr = optimset('Display', 'iter');
            obj = obj.AssignOptions(varargin{:});
        end
    end   
end

methods (Hidden, Access = protected)
    function obj = AssignOptions(obj, varargin)
        option_struct = parse_option_list(varargin{:});
        for field = fieldnames(option_struct)'
            obj.(field{:}) = option_struct.(field{:});
        end
    end
end

end
