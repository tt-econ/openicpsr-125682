function testClusterVCov
%
% Unit test for ClusterVCov method of class MleEstimationOutput
%
    % Preliminaries
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    rng(12345)
    estopts = MleEstimationOptions('quiet', 1, 'ktr', ...
        optimset('Display', 'off', 'TolFun', 1e-14, 'TolX', 1e-14, 'TolCon', 1e-14));
    
    % initiate model
    data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
                  'Delimiter', ',', 'ReadVarNames', true);
    data.var = data.var(1:10^4,:);    
    data.var.Properties.VarNames{6} = 'y';
    regmodel = LinearRegressionModel('y', {'x1','x2'});
    est = regmodel.Estimate(data, estopts);

    % confirm that if clusters are unique across obs, then 
    %   ClusterVCov = vcov_sandwich*[finite sample adjustment]
    assertElementsAlmostEqual(est.vcov_sandwich * (est.nobs/(est.nobs-1)), ...
                              est.ClusterVCov([1:est.nobs]'), 'absolute', 10^-12)
    assert(~isequal(est.ClusterVCov([1:est.nobs]'),est.ClusterVCov(mod([1:est.nobs]',100))));
    
    % confirm that method breaks if clustervar isn't correctly sized
    assertbad('est.ClusterVCov([1:est.nobs-1]'')')
    assertbad('est.ClusterVCov([1:est.nobs])')
    
    % write checksum
    write_checksum('../../log/checksum.log', 'ClusterVCov',...
        est.ClusterVCov([1:est.nobs]'), est.ClusterVCov(round(rand(est.nobs, 1)*4)));
end

