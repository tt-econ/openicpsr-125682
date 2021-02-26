function grouplik = GetGroupLikelihoods(obj, param, data, estopts)
%
% Return the likelihoods by group for a dataset given paramters.
% Output is the unconditional likelihood, integrating over model
% unobservables. This is a public wrapper for the private method
% ComputeLikelihoodByGroup().
%
% INPUTS
%   - param: Vector of parameters at which to compute likelihood.
%   - data: An MleData object.
%   - estopts: An MleEstimationOptions object.
%
% OUTPUTS
%   - grouplik: A vector of likelihoods by group.
%

if nargin == 3
    estopts = MleEstimationOptions();
end
assert( obj.IsValidParameterVector(param) );
[nodes, weights, data_rep] = obj.ComputeNodesAndWeights(data, estopts.quadacc);
grouplik = obj.ComputeLikelihoodByGroup(param, data_rep, nodes, weights);