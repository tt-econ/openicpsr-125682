function [stats, dstats] = PlayStats( obj, vcov, dvcov )

% Outputs statistics based on a variance-covariance matrix.
% 
% INPUTS:
%
%  - vcov:  Variance-covariance matrix
%
%  - dvcov: Variance-covariance matrix for derived parameters
% 
% OUTPUTS:
%  - stats: Struct containing the following calculated from vcov:
%
%         se:        standard error
%         z_score:   z-score using standard error
%         p_value:   p-value using standard error for the test H0 = the parameter is zero
%         ci_high:   95% normal confidence interval high value using standard error
%         ci_low:    95% normal confidence interval low value using standard error
%
%  - dstats: Struct containing the following calculated from dvcov:
%
%         se:        standard error
%         z_score:   z-score using standard error
%         p_value:   p-value using standard error for the test H0 = the parameter is zero
%         ci_high:   95% normal confidence interval high value using standard error
%         ci_low:    95% normal confidence interval low value using standard error
%

    % set constants
    confidence = 97.5;
    se_dist = norminv(confidence/100);
    
    % compute statistics    
    stats  = compute_stats(obj.param, vcov, se_dist);
    
    % compute statistics for derived parameters
    if ~isempty(dvcov)
        dstats = compute_stats(obj.dparam, dvcov, se_dist);
    else
        dstats = struct();
    end

end

function stats = compute_stats(param, vcov, se_dist)
    stats.se = sqrt(diag(vcov));
    nparam = length(param);
    
    stats.z_score = param ./ stats.se;            
    stats.p_value = (1 - normcdf(abs(stats.z_score))) * 2;
    stats.ci_high = param + stats.se *  se_dist;
    stats.ci_low = param - stats.se *  se_dist;
end