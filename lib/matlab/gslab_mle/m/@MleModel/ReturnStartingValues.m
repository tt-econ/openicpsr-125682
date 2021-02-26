function startparam = ReturnStartingValues(obj, start_paramlist, start_values)
%
% ReturnStartingValues returns a new set of starting values for start_paramlist
%   based on those provided in start_values. 
%
% INPUTS
%   - start_paramlist: Cell array of names of a subset of model parameters.
%   - start_values: Vector of parameter values ordered according to start_paramlist.
%
% OUTPUTS
%   - startparam: Vector of starting values for model. For parameters in start_paramlist, these 
%                 come from start_values; otherwise, they come from obj.default_startparam.
%
assert( all(ismember(start_paramlist,obj.paramlist)) );
startparam = obj.default_startparam;
indices = obj.indices;
for i = 1:length(start_paramlist)
    startparam(indices.(start_paramlist{i})) = start_values(i);
end