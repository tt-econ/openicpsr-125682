function [f,g,h] = test_ff(param)

global cmat cvec pos

paramt = transform('log',pos,param);
paramtc = constrain(cmat,paramt);

f = paramtc(1)^2 + paramtc(2)^2 + prod(paramtc);

gtc = zeros(2,1);
htc = zeros(2,2);
for i = 1:2
    gtc(i) = 2*paramtc(i) + prod(paramtc)/paramtc(i);
    for j = 1:2
        if i==j
            htc(i,j) = 2;
        else
            htc(i,j) = prod(paramtc)/(paramtc(i)*paramtc(j));
        end
    end
end

[~,gt,~,ht] = unconstrain(cmat,cvec,paramtc,gtc,[],htc);
[~,g,~,h] = untransform('log',pos,paramt,gt,[],ht);