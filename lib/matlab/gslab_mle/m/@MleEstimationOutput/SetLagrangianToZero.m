function est = SetLagrangianToZero( obj, paramlist )
% 
% Sets the Lagrangian of bound constraints to zero for a subset of
% parameters.
%
% INPUTS
%
%    - paramlist: Cell array of names of parameters that the user is
%    declaring to have Lagrangian of zero.
%
% OUTPUTS
%    - est: Copy of obj with Lagrangians set to zero for paramlist.
% 
%

est = obj;

if nargin==1
    paramlist = est.model.paramlist;
end

for name = paramlist
    est.lambda.lower(est.model.indices.(char(name)))=0;
    est.lambda.upper(est.model.indices.(char(name)))=0;
end

end

