function PlayFull( obj, vcov, dvcov, play_nparam )
%
% PlayFull Outputs a human-readable readable summary of MleEstimationOutput
% including confidence intervals and standard errors.
%

[stats, dstats] = obj.PlayStats(vcov, dvcov);

wald_test = obj.WaldTest(eye(obj.model.nparam),[],zeros(obj.model.nparam,1),10^-8);

disp(' ');
disp(' ');
disp('RESULTS');
disp(' ');
fprintf('MODEL: %10s\n', class(obj.model));
disp(' ');
fprintf('LOG LIKELIHOOD: %15.4f\n', obj.fval);
fprintf('NUMBER OF OBS:  %15.0f\n', obj.nobs);
fprintf('WALD CHI2:%21.3e\n', [wald_test.wald_statistic]);
fprintf('WALD P-VALUE:   %15.4f\n', wald_test.pvalue);
disp(' ')

disp('PARAMETER ESTIMATES');
DisplayHeader

for r=1:play_nparam
    PrintEstimates(obj.model.paramlist{r}, obj.param(r), stats.se(r), ...
        stats.z_score(r), stats.p_value(r), stats.ci_low(r), stats.ci_high(r))
end
disp(' ');

if ~isempty(obj.model.dparamlist)
    disp('DERIVED PARAMETER ESTIMATES');
    DisplayHeader
    for r=1:obj.model.ndparam
        PrintEstimates(obj.model.dparamlist{r}, obj.dparam(r), dstats.se(r), ...
            dstats.z_score(r), dstats.p_value(r), dstats.ci_low(r), dstats.ci_high(r))
    end
    disp(' ');
end

end

function DisplayHeader
    disp(' ');
    disp('          Parameter           ');
    disp('----------------------------- ');
    disp('                                Est         SE         Z        P>|z|     [95% Conf. Interval] ');
end

function PrintEstimates(paramname, param, se, z, p, ci_low, ci_high)
        fprintf('%-26s %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f\n', paramname, ...
            [param se z p ci_low ci_high ]);
end
