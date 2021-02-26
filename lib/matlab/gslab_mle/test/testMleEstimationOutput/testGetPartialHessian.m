function testGetPartialHessian
%
% Unit test for methods GetParamSubset and GetVCovSubset
%
    % Preliminaries
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'test'))) 
    rng(12345)
    
    % Set options, define data and model
    estopts = MleEstimationOptions('quiet', 1);
	data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
				  'Delimiter', ',', 'ReadVarNames', true);
	data.var = data.var(1:10^4,:);	
    
    regmodel = LinearRegressionModel('y_norm', {'x1','x2'});
    est = regmodel.Estimate(data, estopts);
    hessian = est.hessian;
    
    hess_full = est.GetPartialHessian(est.model.paramlist, est.model.paramlist);
    assertEqual(hessian, hess_full);
    hess_row1 = est.GetPartialHessian({'constant'}, est.model.paramlist);
    assertEqual(hessian(1,:), hess_row1);
    hess_fliplr = est.GetPartialHessian(est.model.paramlist, fliplr(est.model.paramlist));
    assertEqual(fliplr(hessian), hess_fliplr);
    hess_flipud = est.GetPartialHessian(fliplr(est.model.paramlist), est.model.paramlist);
    assertEqual(flipud(hessian), hess_flipud);
    
    assertbad('est.GetPartialHessian(est.model.paramlist, "george")')
    assertbad('est.GetPartialHessian("george", est.model.paramlist)')
    assertbad('est.GetPartialHessian(est.model.paramlist, {"constant", "constant"})')
    assertbad('est.GetPartialHessian({"constant", "constant"}, est.model.paramlist)')
    
    % Write checksum
    write_checksum('../../log/checksum.log', 'GetPartialHessian', hess_full);
end
