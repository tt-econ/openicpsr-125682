%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% UNTRANSFORM.M: Untransform parameter vector / derivatives 
%
%   Input pos is vector of indices into param equal to 1 if the parameter should be constrained 
%   to be strictly positive and zero otherwise.
%
%   The inputs gradt, Vt, and hesst are optional.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [param grad V hess] = untransform(type,pos,paramt,gradt,Vt,hesst) 

% count parameters
nparam = length(paramt);

% make sure pos is logical
pos = logical(pos);

% set grad and hess to be empty arrays by default
grad=[];
V=[];
hess=[];

% define terms
theta = paramt;
fd = ones(nparam,1);
fdd = zeros(nparam,1);
if strcmp(type,'log')
    theta(pos) = exp(paramt(pos));
    fd(pos) = 1./theta(pos);
    fdd(pos) = -1./theta(pos).^2;
elseif strcmp(type,'abs')
    theta(pos) = abs(paramt(pos)); 
    fd(pos) = (paramt(pos)>=0) - (paramt(pos)<0);
    fdd(pos) = 0;
end

% untransform parameters
param = theta;

% untransform gradient
if nargin>=4 && ~isempty(gradt)
    assert(length(gradt) == nparam,...
             'Error in inputs');
    grad = gradt.*fd;
end

% untransform variance-covariance matrix
if nargin>=5 && ~isempty(Vt)
    assert(isequal(size(Vt),[nparam nparam]),...
             'Error in inputs');
    V = Vt;
    for i = 1:nparam
        for j = 1:nparam
            if i==j && pos(i)
                V(i,j)= Vt(i,i)/fd(i)^2;
            elseif i~=j && (pos(i) || pos(j))
                V(i,j) = Vt(i,j)/(fd(i)*fd(j));
            end
        end
    end
end

% untransform hessian
if nargin==6 && ~isempty(hesst)
    assert(isequal(size(hesst),[nparam nparam]),...
             'Error in inputs');
    hess = hesst;
    for i = 1:nparam
        for j = 1:nparam
            if i==j && pos(i)
                hess(i,j)= hesst(i,j)*fd(i)^2 + gradt(i)*fdd(i);
            elseif i~=j && (pos(i) || pos(j))
                hess(i,j) = hesst(i,j)*fd(i)*fd(j);
            end
        end
    end
end








