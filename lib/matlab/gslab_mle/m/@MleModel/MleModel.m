classdef (Abstract) MleModel < Model
%
% MleModel: Abstract class that provides a template for user-defined maximum 
%   likelihood models
%
% To implement a model, the user defines a subclass of the abstract class MleModel. A valid 
% implementation must (i) specifiy the abstract properties which define the model's elements;
% (ii) implement the following methods:
%
% clik = ComputeConditionalLikelihoodVector(obj, param, data)
%     Takes as input a parameter vector and data, 
%     including values for all unobservables, and returns a vector of likelihoods with one 
%     element per observation. The likelihoods are conditional in the sense that they depend 
%     on the values of the unobservables.
% 
%     INPUTS
%       - param: Vector of parameters at which to compute likelihoods.
%       - data: An MleData object.
% 
%     OUTPUTS
%       - clik: A real vector of conditional likelihoods with one element per
%             observation in the input data.
%
% lhs = ComputeOutcomes(obj, param, data) 
%     Takes as input a parameter vector and data, including values for all unobservables and 
%     errors, and returns a vector of outcomes.
% 
%     INPUTS
%       - param: Vector of parameters at which to compute likelihoods.
%       - data: An MleData object.
% 
%     OUTPUTS
%       - lhs: A struct with one field for each outcome variable.
%
% The user may optionally implement versions of the TransformUnobservables(), TransformErrors(),
% and DerivedParam methods. See the headers to these .m files for details.
%
% A parameter vector must be a real column vector with length equal to the number 
% of elements in the 'paramlist'  property.
%
% All unobservables in indiv_unobs_list and group_unobs_list are assumed to be standard normal
% and are integrated by sparse grid integration.
%
% The remaining properties and methods of MleModel are available to all
% subclasses and should not typically need to be modified for specific 
% implementations.
%
% The constructor MleModel() can be called with no arguments, with a single
% struct as an argument, or with a list of option-value pairs as arguments.
% In the second case, each field of the struct must be the name of a valid
% option (i.e., property of the implementing subclass); the options will be
% set to the values of the respective fields. In the third case, each
% odd input argument must be the name of a valid option; the options will
% be set to the values of the respective even input arguments.
%
% Examples (for an implementing subclass called MyModel):
%    model = MyModel();
%    model = MyModel(option_struct);
%    model = MyModel('option1', 6, 'option2', 'blue');
%

properties (Abstract)
    group_unobs_list;       % Names of group-level unobservables (integrated numerically)
    indiv_unobs_list;       % Names of indiv-level unobservables (integrated numerically)
    error_list;             % Names of indiv-level errors (not integrated numerically)    
    error_distributions;    % Struct giving distributions of raw error terms
    error_dimensions;       % Struct giving # dimensions per obs of raw error terms
    dparamlist;             % Cell array of derived parameter names
end

methods (Abstract, Hidden, Access = protected)
    clik = ComputeConditionalLikelihoodVector(obj, param, data)
    lhs = ComputeOutcomes(obj, param, data)
end

properties (Dependent)
    numerical_integral;     % Indicator for model requiring numerical integration
    ngroup_unobs;           % Number of group-level unobservables
    nindiv_unobs;           % Number of indiv-level unobservables
    nerrors;                % Number of error terms
    ndparam;                % Number of derived parameters
    dindices;               % Struct giving the index of each derived parameter
end

methods
    function obj = MleModel(varargin)
    % Create new Model object
        if nargin > 0 && ~(nargin == 1 && IsValidModel(varargin{1}))
            obj = obj.AssignOptions(varargin{:});
        end
        assert( IsValidModel(obj) );
    end

    function numerical_integral = get.numerical_integral(obj)
        numerical_integral = ~isempty(obj.group_unobs_list) || ~isempty(obj.indiv_unobs_list);
    end

    function num = get.ngroup_unobs(obj)
        num = length(obj.group_unobs_list);
    end

    function num = get.nindiv_unobs(obj)
        num = length(obj.indiv_unobs_list);
    end

    function num = get.nerrors(obj)
        num = length(obj.error_list);
    end

    function n = get.ndparam(obj)
        n = length(obj.dparamlist);
    end

    function ind = get.dindices(obj)
        ind = cell2struct(num2cell(1:obj.ndparam)', obj.dparamlist);
    end

    est = Estimate(obj, data, estopts)
    simdata = Simulate(obj, param, data, simopts)
    [est, bootstrap_reps] = ParametricBootstrap(obj, data, param_true, reps, estopts)
    startparam = ReturnStartingValues(obj, paramlist, param)
    
    clik = GetConditionalLikelihoods(obj, param, data)
    grouplik = GetGroupLikelihoods(obj, param, data, estopts)
    sumloglik = GetSumLogLik(obj, param, data, estopts)
    dparam = GetDerivedParam(obj, param, constants, dparamlist)
end

methods (Hidden, Access = protected)
	dparam = DerivedParam(obj, param, constants, dparamname)
    unobs = TransformUnobservables(obj, param, data, raw_unobs)
    error = TransformErrors(obj, param, data, raw_error)
    [raw_unobs, raw_error] = DrawErrorsAndRawUnobs(obj, data, simopts)
    [nodes, weights, data_rep] = ComputeNodesAndWeights(obj, data, quadacc)
    grouplik = ComputeLikelihoodByGroup(obj, param, data, nodes, weights)
    bool = IsValidDataForModel(obj, data)
    bool = IsValidModel(obj)
end

end

