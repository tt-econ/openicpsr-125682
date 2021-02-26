function vcov_cluster = ClusterVCov(obj, clustervar)
%
% Calculates clustered variance-covariance estimate, with finite-sample adjustment. 
% See Stata Manual [U] 20 Estimation and postestimation commands, pp. 295-296.
%
% INPUTS
%
%    - clustervar: obj.nobs length column vector which indicates how observations should be clustered.
%
% OUTPUTS
%
%    - vcov_cluster: Sandwich estimator of vcov in which observations are only independent within clusters.
%                    
%

assert(isequal(size(clustervar), [obj.nobs 1]));

m = length(unique(clustervar));
u = sumwithin(obj.jacobian, clustervar);

vcov_cluster = obj.TransformVCovUsingConstraints(obj.active_jacobian,...
   ((obj.hessian)^(-1) * m/(m-1) * (u' * u) * (obj.hessian)^(-1))^(-1));

end
