function svcov = GetVCovSubset(obj, subparamlist)
%
% Returns variance-covariance matrix for a subset of parameters.
% Subset can include derived parameters.
%
% INPUTS
%
%    - subparamlist: Cell array of names of parameters and/or derived parameters.
%
% OUTPUTS
%
%    - sparam: Variance-covariance matrix of parameters in subparamlist.
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

[~, cvcov] = obj.DeltaMethod(eye(obj.model.nparam), ...
            @(param)obj.model.GetDerivedParam(param, obj.const));

svcov = cvcov(subindexvec,subindexvec);

end