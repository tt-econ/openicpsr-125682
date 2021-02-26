global cmat cvec pos

epsilon = 10^-9;

cmat = [1     1     0     0;
        0     0     1     0];
cvec = [1;2];
pos = logical([0;0;0;0]);
param = [0.6549;0.3451;2.0000;7];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% test function of constrained gradients and hessian
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
paramt = transform('log',pos,param);
paramtc = constrain(cmat,paramt);

[~,gtc,htc] = test_fftc(paramtc);

% numerical gradient
gtcn = zeros(2,1);
for i = 1:2
    paramplustc = paramtc;
    paramplustc(i) = paramtc(i) + epsilon;
    gtcn(i) = (test_fftc(paramplustc) - test_fftc(paramtc))/epsilon;
end
display(['Max difference in constrained gradients is ' num2str(max(abs(gtcn-gtc)))])

% numerical hessian
htcn = zeros(2,2);
for i = 1:2
    for j = 1:2
        paramplustc = paramtc;
        paramplustc(j) = paramtc(j) + epsilon;
        [~,gplustc] = test_fftc(paramplustc);
        htcn(i,j) = (gplustc(i)-gtc(i))/epsilon;
    end
end
display(['Max difference in constrained hessians is ' num2str(max(abs(htcn(:)-htc(:))))])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% test function of unconstrained gradients and hessian
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[~,g,h] = test_ff(param);

% numerical gradient
gn = zeros(4,1);
for i = 1:4
    paramplus = param;
    paramplus(i) = param(i) + epsilon;
    gn(i) = (test_ff(paramplus) - test_ff(param))/epsilon;
end
display(['Max difference in unconstrained gradients is ' num2str(abs(max(gn-g)))])

% numerical hessian
hn = zeros(4,4);
for i = 1:4
    for j = 1:4
        paramplus = param;
        paramplus(j) = param(j) + epsilon;
        [~,gplus] = test_ff(paramplus);
        hn(i,j) = (gplus(i)-g(i))/epsilon;
    end
end
display(['Max difference in unconstrained hessians is ' num2str(abs(max(hn(:)-h(:))))])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% test functions on variance-covariance matrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

epsilon = randn(2,1000);
Vtc = (1/1000).*epsilon*epsilon';
paramdraws = zeros(4,1000);
paramdrawst = zeros(4,1000);
for i=1:1000
    paramdrawst(:,i) = unconstrain(cmat,cvec,paramtc+epsilon(:,i));
    paramdraws(:,i) = untransform('log',pos,paramdrawst(:,i));
end
V = (1/1000).*(paramdraws-repmat(param,1,1000))*(paramdraws-repmat(param,1,1000))';

[~,~,Vt_test,~] = transform('log',pos,param,[],V,[]);
[~,~,Vtc_test,~] = constrain(cmat,paramt,[],Vt_test,[]);
display(['Max difference in constrained Vs is ' num2str(max(abs(Vtc_test(:)-Vtc(:))))])

[~,~,Vt_test,~] = unconstrain(cmat,cvec,paramtc,[],Vtc,[]);
[~,~,V_test,~] = untransform('log',pos,paramt,[],Vt_test,[]);
display(['Max difference in unconstrained Vs is ' num2str(max(V_test(:)-V(:)))])

