function clik = GetConditionalLikelihoods(obj, param, data)
%
% Return vector of conditional likelihoods for each observation
% in a dataset given parameters. This is a public wrapper for the private
% ComputeConditionalLikelihood method.
%
% INPUTS
%   - param: Vector of parameters at which to compute likelihoods.
%   - data: An MleData object.
%
% OUTPUTS
%   - clik: A real vector of conditional likelihoods with one element per
%         observation in the input data.
%

assert( obj.IsValidParameterVector(param) );
clik = obj.ComputeConditionalLikelihoodVector(param, data);