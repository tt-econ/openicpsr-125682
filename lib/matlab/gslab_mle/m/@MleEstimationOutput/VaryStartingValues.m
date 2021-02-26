function estimates = VaryStartingValues(obj, data, nstart, lb, ub, estopts)
%
% Draw starting values uniformly on specified range and estimate model
% from each set of starts.
%
% INPUTS
%
%   - data: An MleData object
%   - nstart: Number of starting values to try
%   - lb: Lower bound of range of starting values
%   - ub: Upper bound of range of starting values
%
% OUTPUTS
%   - estimates: An MleStartTestOutput object
%

    if nargin<=5
         estopts = obj.estopts;
    end
    
    model = obj.model;
    estimates = deal( cell(nstart, 1) );
    for i = 1 : nstart
        estopts.startparam = lb+rand(size(obj.param)).*(ub-lb);
        estimates{i} = model.Estimate(data, estopts);        
    end
        
    estimates = MleStartTestOutput(estimates, obj, lb, ub);

end
