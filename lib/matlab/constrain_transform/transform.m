%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% TRANSFORM.M: Transform parameter vector / derivatives
%
%   Input pos is vector of indices into param equal to 1 if the parameter should be constrained 
%   to be strictly positive and zero otherwise.
%
%   The inputs grad, V, and hess are optional.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [paramt gradt Vt hesst] = transform(type,pos,param,grad,V,hess) 

% count parameters
nparam = length(param);

% make sure pos is logical
pos = logical(pos);

% set gradt and hesst to be empty arrays by default
gradt=[];
Vt=[];
hesst=[];

% define terms
theta = param;
f = theta;
fd = ones(nparam,1);
fdd = zeros(nparam,1);
if strcmp(type,'log')
    f(pos) = log(theta(pos));
    fd(pos) = 1./theta(pos);
    fdd(pos) = -1./theta(pos).^2;
elseif strcmp(type,'abs')
    % no change in this case because theta(pos)>=0
    assert(min(theta(pos)>=0)==1,'Negative value for parameter constrained to be positive');
end

% transform parameters
paramt = f; 

% transform gradient
if nargin>=4 && ~isempty(grad)
    assert(length(grad) == nparam,...
             'Error in inputs');
    gradt = grad./fd;
end

% transform variance-covariance matrix
if nargin>=5 && ~isempty(V)
    assert(isequal(size(V),[nparam nparam]),...
         'Error in inputs');
    Vt = V;
    for i = 1:nparam
        for j = 1:nparam
            if i==j && pos(i)
                Vt(i,i)= V(i,i)*fd(i)^2;
            elseif i~=j && (pos(i) || pos(j))
                Vt(i,j) = V(i,j)*(fd(i)*fd(j));
            end
        end
    end
end

% transform hessian
if nargin==6 && ~isempty(hess)
    assert(isequal(size(hess),[nparam nparam]),...
         'Error in inputs');
    hesst = hess;
    for i = 1:nparam
        for j = 1:nparam
            if i==j && pos(i)
                hesst(i,i)= (hess(i,i)-grad(i)*fdd(i)/fd(i)) * fd(i)^(-2);
            elseif i~=j && (pos(i) || pos(j))
                hesst(i,j) = hess(i,j)/(fd(i)*fd(j));
            end
        end
    end
end




