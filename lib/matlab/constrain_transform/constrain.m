%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% CONSTRAIN.M: Map unconstrained parameter vector / derivatives to constrained
%
%   Input R is a matrix defining arbitrary linear constraints.
%
%   The inputs grad, V, and hess are optional. See "makecns" in Stata
%   reference manual for discussion of method.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [paramc gradc Vc hessc] = constrain(R,param,grad,V,hess) 

% error checking
nparam = size(R,2);
assert(length(param) == nparam,...
        'Error in inputs');

% set gradc, Vc and hessc to be empty arrays by default
gradc=[];
Vc=[];
hessc=[];

% define transformation matrix
mat = eye(nparam)-R'/(R*R')*R;
T = orth(mat);

% constrain parameters
paramc = (param'*T)';

% constrain gradient
if nargin>=3 && ~isempty(grad)
    assert(length(grad) == nparam,...
             'Error in inputs');
    gradc = (grad'*T)';
end

% constrain variance-covariance matrix
if nargin>=4 && ~isempty(V)
    assert(isequal(size(V),[nparam nparam]),...
         'Error in inputs');
    Vc = T'*V*T;
end

% constrain hessian
if nargin==5 && ~isempty(hess)
    assert(isequal(size(hess),[nparam nparam]),...
         'Error in inputs');
    hessc = T'*hess*T;
end



