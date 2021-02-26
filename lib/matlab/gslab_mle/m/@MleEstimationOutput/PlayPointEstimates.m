function PlayPointEstimates( obj , play_nparam)
%
% PlayPointEstimates Outputs a human-readable readable summary of MleEstimationOutput
% excluding statistics that depend on estimating a variance-covariance
% matrix
%

disp(' ');
disp(' ');
disp('RESULTS');
disp(' ');
fprintf('MODEL: %10s\n', class(obj.model));
disp(' ');
fprintf('LOG LIKELIHOOD: %15.4f\n', obj.fval);
fprintf('NUMBER OF OBS:  %15.0f\n', obj.nobs);
disp(' ')

disp('PARAMETER ESTIMATES');
DisplayHeader

for r=1:play_nparam
    PrintEstimates(obj.model.paramlist{r}, obj.param(r))
end
disp(' ');

if ~isempty(obj.model.dparamlist)
    disp('DERIVED PARAMETER ESTIMATES');
    DisplayHeader
    for r=1:obj.model.ndparam
        PrintEstimates(obj.model.dparamlist{r}, obj.dparam(r))
    end
disp(' ');
end    

end

function DisplayHeader
    disp(' ');
    disp('          Parameter           ');
    disp('----------------------------- ');
    disp('                                Est         ');
end

function PrintEstimates(paramname, param)
        fprintf('%-26s  %10.4f\n', paramname,param); 
end
