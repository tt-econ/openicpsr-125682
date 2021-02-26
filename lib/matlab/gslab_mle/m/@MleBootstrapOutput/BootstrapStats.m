function stats = BootstrapStats( param_matrix, param_true )

% Outputs statistics based on matrix of parameters produced in a bootstrap.
% 
% INPUTS:
%
%  - param_matrix: Matrix of estimates from bootstrap replications
%
%  - param_true: True parameters used in bootstrap
% 
% OUTPUTS:
%  - stats: Struct containing the following:
%
%         z:         z-score using bootstrap standard error
%         p:         p-value using bootstrap standard error for the test H0 = the parameter is zero
%         ci_high:   95% normal confidence interval high value using bootstrap standard error
%         ci_low:    95% normal confidence interval low value using bootstrap standard error
%         pci_high:  95% percentile confidence interval high value 
%         pci_low:   95% percentile confidence interval low value
%         bci_high:  95% bias-corrected confidence interval high value 
%         bci_low:   95% bias-corrected confidence interval low value 
%

    % set constants
    confidence = 97.5;
    se_dist = norminv(confidence/100);
    za = norminv(confidence/100);
    
    % initialize output and compute statistics
    stats = struct();
    se = sqrt(diag(cov(param_matrix)));  
    stats.z = param_true./se;
    stats.p = 2 * (ones(size(stats.z))-normcdf(abs(stats.z)));
    stats.ci_high = param_true + se_dist * se;
    stats.ci_low  = param_true - se_dist * se;
    stats.pci_high = prctile(param_matrix, confidence)';
    stats.pci_low  = prctile(param_matrix, (100-confidence))';
    z0 = norminv(mean(param_matrix <= param_true(:,ones(size(param_matrix, 1),1))'))';
    stats.bci_high = diag(prctile(param_matrix, 100 * normcdf(2 * z0 + za)));
    stats.bci_low  = diag(prctile(param_matrix, 100 * normcdf(2 * z0 - za)));
end

