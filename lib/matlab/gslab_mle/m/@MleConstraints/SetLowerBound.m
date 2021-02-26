function constr = SetLowerBound(obj, constr_paramlist, bounds)
%
% Update the lower bound constraints of parameters in constr_paramlist 
%
% INPUTS
%
%    - constr_paramlist:   A subset of obj.paramlist containing the parameters to be constrained   
%    
%    - bounds:             A vector with the same length as constr_paramlist that
%                          defines the lower bounds for all parameters in constr_paramlist
%
% OUTPUTS
%
%    - constr:             a copy of the object with obj.lb modified to set
%                          the desired constraints 
%

nparam = obj.nparam;
indices = obj.indices;

if ~iscell(constr_paramlist)
    constr_paramlist = {constr_paramlist};
end

ncparam = length(constr_paramlist);
assert(ncparam == length(bounds));

constr = obj;

if isempty(constr.lb)
    constr.lb = -Inf(1, nparam);
end

for i = 1 : ncparam
    constr.lb(indices.(constr_paramlist{i})) = bounds(i);
end

end