% Benchmark test for transform_group mex function

% Comparing the speed of transform_group written in C and 
% an equivalent function written in Matlab

function benchmark_transform_group    
    % Preliminaries
    addpath(genpath('../mex'));    
    diary off    
    delete '..\log\benchmark_transform_group.log'
    echo on
    diary '..\log\benchmark_transform_group.log'

    ntest = 100;
    rand('twister', 10);

    % Number of group with 2, 3, 4 and 10 elements
    n2 = 1000;
    n3 = 2000;
    n4 = 3000;
    n10 = 10^4;    
    [data, group, vcov, vcov_id] = get_input_sets(ntest, n2, n3, n4, n10);    
    
    disp(['For ', num2str(ntest), ' tests with 4 unique var-cov matrices and nobs = ', ...
        num2str(length(data{1})), ':']);
    
    % Use mex function and check the time used
    tStart = tic;
    for i = 1 : ntest
        transform_group(data{i}, group{i}, vcov{i}, vcov_id{i});
    end
    mex_time = toc(tStart);    
    disp('Mex time in seconds:');
    disp(mex_time);
    
    % Use Matlab function and check the time used: same algorithm with mex
    % function
    tStart = tic;
    for i = 1 : ntest
        transform_group_matlab_efficient(data{i}, group{i}, vcov{i}, vcov_id{i});
    end
    matlab_time_efficient = toc(tStart);    
    disp('Matlab time in seconds if we use the same algorithm as the Mex function:');
    disp(matlab_time_efficient);        
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Uncomment the section below to see how the inefficient algorithm does
    % This won't work with nobs being too large due to memory overflow
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % tStart = tic;
    % for i = 1 : ntest
    %    transform_group_matlab(data{i}, group{i}, vcov{i}, vcov_id{i});
    %end
    %matlab_time_inefficient = toc(tStart);
    %disp('Matlab time in seconds if we do not take advantage of the transformation matrix being sparse:');
    %disp(matlab_time_inefficient);        
    
    diary off
end

function [data, group, vcov, vcov_id] = get_input_sets(ntest, n2, n3, n4, n10)
    group = cell(1, ntest);
    data = cell(1, ntest);
    vcov = cell(1, ntest);
    vcov_id = cell(1, ntest);

    % Create ntest different input sets
    for t = 1 : ntest
        % 4 random lower triangles
        L2 = tril(rand(2, 2)); 
        L3 = tril(rand(3, 3));
        L4 = tril(rand(4, 4));   
        L10 = tril(rand(10, 10));   
    
        % Symmetric positive definite matrices
        V2 = L2 * L2';
        V3 = L3 * L3';
        V4 = L4 * L4';
        V10 = L10 * L10';    

        % Total number of observations
        n = n2 * 2 + n3 * 3 + n4 * 4 + n10 * 10;
  
        group{t} = zeros(n, 1);
        vcov_id{t} = zeros(n2 + n3 + n4 + n10, 1);
    
        % Create input parameters
        data{t} = rand(n, 1);
        group{t} = zeros(n, 1);    
        vcov_id{t} = zeros(n2 + n3 + n4 + n10, 1);
        group{t}(1 : 2*n2) = (((1:2*n2)+1)/2)';
        group{t}(2*n2+1 : 2*n2+3*n3) = n2 + (((1:3*n3)+2)/3)';
        group{t}(2*n2+3*n3+1 : 2*n2+3*n3+4*n4) = n2 + n3 + (((1:4*n4)+3)/4)';
        group{t}(2*n2+3*n3+4*n4+1 : 2*n2+3*n3+4*n4+10*n10) = n2 + n3 + n4 + (((1:10*n10)+9)/10)';
        group{t} = floor(group{t});
        vcov_id{t}(1 : n2) = 1;
        vcov_id{t}(n2+1 : n2+n3) = 2;
        vcov_id{t}(n2+n3+1 : n2+n3+n4) = 3;
        vcov_id{t}(n2+n3+n4+1 : n2+n3+n4+n10) = 4;
    
        vcov{t} = {V2, V3, V4, V10};       
    end
end

function output = transform_group_matlab(data, group, vcov, vcov_id) 
    if (min(size(data)) ~= 1) || (min(size(group)) ~= 1) || (min(size(vcov)) ~= 1) ...
            || (min(size(vcov_id)) ~= 1) 
        disp('All input parameters should be vectors.');
        return;
    end
    nobs = length(data);
    if length(data) ~= length(group)
        disp('Data and group should have the same number of observations');
        return;
    end
    
    ngroup = length(vcov_id);
    group_size = zeros(1, ngroup);
    for i = 1 : nobs - 1
        if group(i) > group(i + 1)
            disp('Group index has to be sorted from low to high.');
            return;
        end
        group_size(group(i)) = group_size(group(i)) + 1; 
    end
    group_size(group(nobs)) = group_size(group(nobs)) + 1;
    
    if (group(1) ~= 1) || (group(nobs) ~= ngroup) 
        disp('Group indexing is wrong.');
        return;
    end
    
    nvcov = length(vcov);
    all_chol = cell(1, nvcov);
    for i = 1 : nvcov
        if size(vcov{i}, 1) ~= size(vcov{i}, 2)
            disp('Each vcov matrix has to be square');
            return;
        end
        all_chol{i} = chol(vcov{i}, 'lower');
    end    

    transform_matrix = zeros(nobs, nobs);
    corner = 1;
    for i = 1 : ngroup
        if group_size(i) ~= length(vcov{vcov_id(i)})
            disp('Variance covariance matrix dimensions do not match with group size');                
        end
        transform_matrix(corner : corner + group_size(i) - 1, corner : corner + group_size(i) - 1)...
            = all_chol{vcov_id(i)};
        corner = corner + group_size(i);
    end
    
    output = transform_matrix * reshape(data, nobs, 1);
end

function output = transform_group_matlab_efficient(data, group, vcov, vcov_id) 
    if (min(size(data)) ~= 1) || (min(size(group)) ~= 1) || (min(size(vcov)) ~= 1) ...
            || (min(size(vcov_id)) ~= 1) 
        disp('All input parameters should be vectors.');
        return;
    end
    nobs = length(data);
    if length(data) ~= length(group)
        disp('Data and group should have the same number of observations');
        return;
    end
    
    ngroup = length(vcov_id);
    group_size = zeros(1, ngroup);
    for i = 1 : nobs - 1
        if group(i) > group(i + 1)
            disp('Group index has to be sorted from low to high.');
            return;
        end
        group_size(group(i)) = group_size(group(i)) + 1; 
    end
    group_size(group(nobs)) = group_size(group(nobs)) + 1;
    
    if (group(1) ~= 1) || (group(nobs) ~= ngroup) 
        disp('Group indexing is wrong.');
        return;
    end
    
    nvcov = length(vcov);
    all_chol = cell(1, nvcov);
    for i = 1 : nvcov
        if size(vcov{i}, 1) ~= size(vcov{i}, 2)
            disp('Each vcov matrix has to be square');
            return;
        end
        all_chol{i} = chol(vcov{i}, 'lower');
    end    

    data = reshape(data, nobs, 1);
    output = zeros(nobs, 1);
    oi = 1;
    for i = 1 : ngroup
        if group_size(i) ~= length(vcov{vcov_id(i)})
            disp('Variance covariance matrix dimensions do not match with group size');                
        end
        output(oi : oi + group_size(i) - 1) = ...
            all_chol{vcov_id(i)} * data(oi : oi + group_size(i) - 1);
        oi = oi + group_size(i);
    end
end