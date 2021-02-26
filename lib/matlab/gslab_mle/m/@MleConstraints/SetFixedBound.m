function constr = SetFixedBound(obj, constr_paramlist, bounds)
%
% Update the fixed value constraints of parameters in constr_paramlist 
%
% INPUTS
%
%    - constr_paramlist:   A subset of obj.paramlist containing the parameters to be constrained   
%    
%    - bounds:             A vector with the same length as constr_paramlist that
%                          defines the fixed constraints for all parameters in constr_paramlist
%
% OUTPUTS
%
%    - constr:             a copy of the object with obj.lb and obj.ub modified to set
%                          the desired constraints 
%

constr = SetUpperBound(obj, constr_paramlist, bounds);
constr = SetLowerBound(constr, constr_paramlist, bounds);

end