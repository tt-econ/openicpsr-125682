%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% UNCONSTRAIN.M: Map constrained parameter vector / derivatives to unconstrained
%
%   Inputs R and r are a matrix and vector defining arbitrary linear constraints.
%
%   The inputs gradc and hessc are optional. See "makecns" in Stata
%   reference manual for discussion of method.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param grad V hess] = unconstrain(R,r,paramc,gradc,Vc,hessc) 

% error checking
nparam = size(R,2);
ncons = size(R,1);
assert(length(paramc) == nparam-ncons,...
        'Error in inputs');

% set grad, V, and hess to be empty arrays by default
grad=[];
V=[];
hess=[];

% define transformation matrix
mat = eye(nparam)-R'/(R*R')*R;
T = orth(mat);
L = null(mat);
A = r'/(L'*R')*L';

% unconstrain parameters
param = (paramc'*T'+A)';

% unconstrain gradient
if nargin>=4 && ~isempty(gradc)
    assert(length(gradc) == nparam-ncons,...
             'Error in inputs');
    grad = (gradc'*T')';
end

% unconstrain variance-covariance matrix
if nargin>=5 && ~isempty(Vc)
    assert(isequal(size(Vc),[nparam-ncons nparam-ncons]),...
             'Error in inputs');
    V = T*Vc*T';
end

% unconstrain hessian
if nargin==6 && ~isempty(hessc)
    assert(isequal(size(hessc),[nparam-ncons nparam-ncons]),...
             'Error in inputs');
    hess = T*hessc*T';
end








