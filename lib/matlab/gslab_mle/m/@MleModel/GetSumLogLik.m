function sumloglik = GetSumLogLik(obj, param, data, estopts)
%
% Return sum of log likelihoods for a dataset given paramters.
% Output is the unconditional likelihood, integrating over model
% unobservables.
%
% INPUTS
%   - param: Vector of parameters at which to compute likelihood.
%   - data: An MleData object.
%   - estopts: An MleEstimationOptions object.
%
% OUTPUTS
%   - sumloglik: A scalar giving the sum of the log-likelihood.
%

if nargin == 3
    estopts = MleEstimationOptions();
end
grouplik = obj.GetGroupLikelihoods(param, data, estopts);
sumloglik = sum(log(grouplik));
