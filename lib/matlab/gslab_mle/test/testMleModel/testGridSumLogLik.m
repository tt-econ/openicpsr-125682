function testGridSumLogLik
%
% Unit test for GridSumLogLik method of class MleModel
%

    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'external'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'depend'))) 
    addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'm'))) 
  
    
    data = MleData('File', '../../external/data/test_data.csv', 'format', '%f%f%f%f%f%f%f%f', ...
                   'Delimiter', ',', 'ReadVarNames', true);
    data.var = data.var(1:10^4,:);
    
    estopts = MleEstimationOptions('quiet', 1);
    regmodel = LinearRegressionModel('y_norm', {'x1','x2'});
    est = regmodel.Estimate(data, estopts);
    baseparam = est.param;
    x1est = baseparam(regmodel.indices.x1_coeff);
    x2est = baseparam(regmodel.indices.x2_coeff);
    
    % submit two parameters
    paramlist = {'x1_coeff', 'x2_coeff'};
    gv = {((x1est-1):0.1:(x1est+1)), ((x2est-1):0.1:(x2est+1))};
    [grid likelihood] = regmodel.GridSumLogLik(baseparam, data, paramlist, gv);
    contour(grid{1}, grid{2}, likelihood)
    
    % submit only one parameter
    [grid_x1 lik_x1] = regmodel.GridSumLogLik(baseparam, data, {'x1_coeff'}, ((x1est-1):0.1:(x1est+1)));
    plot(grid_x1, lik_x1)
    
    % try to submit three parameters or no parameters
    paramlist3 = {'x1_coeff','x2_coeff','const'};
    paramlistnull = {};
    assertbad('regmodel.GridSumLogLik(baseparam, data, paramlist3, ((x1est-1):0.1:(x1est+1)))');
    assertbad('regmodel.GridSumLogLik(baseparam, data, paramlistnull, ((x1est-1):0.1:(x1est+1)))');
    
	write_checksum('../../log/checksum.log', 'GridSumLogLik', grid{2}(:,1)', likelihood(:,1)');
	
end

