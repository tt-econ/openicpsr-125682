function [f,gtc,htc] = test_fftc(paramtc)

global cmat cvec pos

paramt = unconstrain(cmat,cvec,paramtc);
param = untransform('log',pos,paramt);

f = param(1)^2 + param(2)^2 + param(3)^2 + param(4)^2 + prod(param);

g = zeros(4,1);
h = zeros(4,4);
for i = 1:4
    g(i) = 2*param(i) + prod(param)/param(i);
    for j = 1:4
        if i==j
            h(i,j) = 2;
        else
            h(i,j) = prod(param)/(param(i)*param(j));
        end
    end
end

[~,gt,~,ht] = transform('log',pos,param,g,[],h);
[~,gtc,~,htc] = constrain(cmat,paramt,gt,[],ht);
