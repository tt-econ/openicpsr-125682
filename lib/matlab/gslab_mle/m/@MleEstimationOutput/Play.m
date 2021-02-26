function Play( obj, vcov, dvcov )
% 
% PLAY Outputs a human-readable readable summary of MleEstimationOutput
%
% INPUTS:
%
%  - vcov:  Variance-covariance matrix (default = obj.vcov)
%
%  - dvcov: Variance-covariance matrix from derived parameters (default = obj.dvcov)
%

switch (nargin)
    case 1
        vcov = obj.vcov;
        dvcov = obj.dvcov;
    case 2
        [~, dvcov] = obj.DeltaMethod([], ...
                        @(param)obj.model.GetDerivedParam(param, obj.const), vcov);
end

[msglast, msgidlast] = lastwarn;

if strcmp(msgidlast, 'MATLAB:singularMatrix')
    disp('Failed to invert to compute variance-covariance marix');
    vcov = [];
    warning('');
end

play_nparam = obj.model.nparam;

disp(' ')
if (obj.play_controls==false) && isprop(obj.model, 'controls')
    disp(' ')
    disp('CONTROLS ARE NOT BEING DISPLAYED')
    disp(' ')
    play_nparam = obj.model.nparam - length(obj.model.controls);
    if isprop(obj.model, 'include_constant')
        if obj.model.include_constant
            play_nparam = play_nparam - 1;
        end
    end
end

disp(' ')
disp('INITIAL VALUES')
disp(' ')

for i = 1 : play_nparam
    fprintf('%-26s %10.4f\n', obj.model.paramlist{i}, obj.estopts.startparam(i));
end



if isempty(vcov)
    obj.PlayPointEstimates(play_nparam);
else
    obj.PlayFull(vcov, dvcov, play_nparam);
end
