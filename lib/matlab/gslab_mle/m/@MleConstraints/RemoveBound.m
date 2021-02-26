function constr = RemoveBound(obj, constr_paramlist)
%
% Remove upper and lower bound constraints of parameters in constr_paramlist 
%
% INPUTS
%
%    - constr_paramlist:   A subset of obj.paramlist containing the parameters whose
%                          upper and lower bounds are to be removed
%
% OUTPUTS
%
%    - constr:             a copy of the object with obj.lb and obj.ub modified to 
%                          remove all upper and lower bound constraints 
%

ncparam = length(constr_paramlist);
constr = SetUpperBound(obj, constr_paramlist, Inf(ncparam, 1));
constr = SetLowerBound(constr, constr_paramlist, -Inf(ncparam, 1));

end