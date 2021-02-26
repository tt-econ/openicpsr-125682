function sparam = GetParamSubset(obj, subparamlist)
%
% Returns estimates of a subset of parameters.
% Subset can include derived parameters.
%
% INPUTS
%
%    - subparamlist: Cell array of names of parameters and/or derived parameters.
%
% OUTPUTS
%
%    - sparam: Estimated values of parameters in subparamlist.
%

cparamlist = [obj.model.paramlist obj.model.dparamlist];
[~, cindices] = parse_name_list(cparamlist);
if nargin==1
    subparamlist = cparamlist;
end

subindexvec = zeros(length(subparamlist),1);
for i=1:length(subparamlist)
    subindexvec(i)=cindices.(subparamlist{i});
end

cparam = [obj.param; obj.dparam];
sparam = cparam(subindexvec);

end