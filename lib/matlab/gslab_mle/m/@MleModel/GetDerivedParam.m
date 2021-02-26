function dparam = GetDerivedParam(obj, param, constants, dparamlist)
%
% Return the derived parameters of the model. This is a public wrapper
% for the private method DerivedParam().
%
% INPUTS
%   - param: Vector of parameters.
%   - constants: Struct consisting of scalar empirical moments.
%   - estopts: An MleEstimationOptions object.
%   - dparamlist: Cell array of names of derived parameters.
%
% OUTPUTS
%   - dparam: A vector of derived parameters with order determined by dparamlist.
%

if nargin==3 || isempty(dparamlist)
    dparamlist = obj.dparamlist;
end
if ischar(dparamlist)
    dparamlist = {dparamlist};
end
ndparam = length(dparamlist);
dparam = zeros(ndparam, 1);

for i=1:ndparam
    dparam(i) = obj.DerivedParam(param, constants, dparamlist{i});
end

