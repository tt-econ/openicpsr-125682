%
% Unit tests for transform_group mex function
%

function test_suite = test_transform_group
    initTestSuite;
end

function nonposdef_test
    rand('twister', 10);
    
    vcov = {[1, 1; 1, 1]};
    n = 100;
    data = randn(n, 1);
    group = floor((((1:n)+1)/2))';
    vcov_id = ones(n/2, 1);
    
    res = transform_group(data, group, vcov, vcov_id);
    
    % 2 possible spectral decomposition
    [v, d] = eig(vcov{1});
    v2 = v;
    v2(:, [1, 2]) = v(:, [2, 1]);
    d2 = [d(2, 2), d(1, 2); d(2, 1), d(1, 1)];

    res1 = zeros(n, 1);
    res2 = zeros(n, 1);
    for i = 1 : n/2
        res1(i*2-1 : i*2) = v * sqrt(d) * data(i*2-1 : i*2);
        res2(i*2-1 : i*2) = v2 * sqrt(d2) * data(i*2-1 : i*2);
    end
    
    diff1 = sum(abs(res1 - res));    
    diff2 = sum(abs(res2 - res));    
    if diff1 < diff2 
        assertElementsAlmostEqual(res, res1, 'Results incorrect');
    else
        assertElementsAlmostEqual(res, res2, 'Results incorrect');
    end
    write_checksum('../log/checksum.log', 'Transform Group - Non positive definite', ...
        num2str(sum(res), '%0.5f'), num2str(mean(res), '%0.5f'));
end

function posdef_simple_test
    % 3 groups, each with 2 elements
    % each varcov is an identity matrix
    data = [1 1 1 1 1 1];
    group = [1 1 2 2 3 3];
    vcov = {[1 0; 0 1]};
    vcov_id = [1 1 1];
    
    res = transform_group(data, group, vcov, vcov_id);
    assertElementsAlmostEqual(res, ones(6, 1), 'Results incorrect');
    write_checksum('../log/checksum.log', 'Transform Group - Positive definite simple Case', res);
end
    
function posdef_large_simple_test
    % 500,000 groups, each with 2 elements
    % each varcov is an identity matrix
    n = 10^6;
    data = ones(1, n);
    group = (((1:n)+1)/2)';
    
    vcov = {[1 0; 0 1]};
    vcov_id = ones(1, n/2);
    res = transform_group(data, group, vcov, vcov_id);
    assertElementsAlmostEqual(res, ones(n, 1), 'Results incorrect');
    write_checksum('../log/checksum.log', 'Transform Group - Postive definite large simple case', ...
        num2str(sum(res), '%0.5f'), num2str(mean(res), '%0.5f'));
end

function posdef_complicated_test
    rand('twister', 100);

    % 3 random lower triangles
    L2 = tril(rand(2, 2));
    L3 = tril(rand(3, 3));
    L4 = tril(rand(4, 4));
    
    % Symmetric positive definite matrices
    V2 = L2 * L2';
    V3 = L3 * L3';
    V4 = L4 * L4';
    
    data = rand(19, 1);
    group = [1 1 2 2 3 3 3 4 * ones(1, 4) 5 * ones(1, 4) 6 * ones(1, 4)];
    vcov = {V2, V3, V4};
    vcov_id = [1 1 2 3 3 3];
    
    res = transform_group(data, group, vcov, vcov_id);
    
    true_res = [L2 * data(1 : 2); L2 * data(3 : 4); L3 * data(5 : 7); L4 * data(8 : 11); ...
        L4 * data(12 : 15); L4 * data(16 : 19)];
    assertElementsAlmostEqual(res, true_res, 'Results incorrect');
    write_checksum('../log/checksum.log', 'Transform Group - Positive definite complicated case', ...
        num2str(sum(res), '%0.5f'), num2str(mean(res), '%0.5f'));    
end

function posdef_large_complicated_test
    rand('twister', 10);

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
    
    % Number of group with 2, 3, 4 and 10 elements
    n2 = 1000;
    n3 = 2000;
    n4 = 3000;
    n10 = 10^5;
    
    % Total number of observations
    n = n2 * 2 + n3 * 3 + n4 * 4 + n10 * 10;
    
    
    % Create input parameters
    data = rand(n, 1);
    
    group = zeros(n, 1);    
    vcov_id = zeros(n2 + n3 + n4 + n10, 1);
    group(1 : 2*n2) = (((1:2*n2)+1)/2)';
    group(2*n2+1 : 2*n2+3*n3) = n2 + (((1:3*n3)+2)/3)';
    group(2*n2+3*n3+1 : 2*n2+3*n3+4*n4) = n2 + n3 + (((1:4*n4)+3)/4)';
    group(2*n2+3*n3+4*n4+1 : 2*n2+3*n3+4*n4+10*n10) = n2 + n3 + n4 + (((1:10*n10)+9)/10)';
    group = floor(group);
    vcov_id(1 : n2) = 1;
    vcov_id(n2+1 : n2+n3) = 2;
    vcov_id(n2+n3+1 : n2+n3+n4) = 3;
    vcov_id(n2+n3+n4+1 : n2+n3+n4+n10) = 4;
    
    vcov = {V2, V3, V4, V10};           
   
    res = transform_group(data, group, vcov, vcov_id);
    
    % True output
    true_res = [];
    ind = 1;
    for i = 1 : n2
        true_res = [true_res; L2 * data(ind : ind + 1)];
        ind = ind + 2;
    end
    
    for i = 1 : n3
        true_res = [true_res; L3 * data(ind : ind + 2)];
        ind = ind + 3;
    end

    for i = 1 : n4
        true_res = [true_res; L4 * data(ind : ind + 3)];
        ind = ind + 4;
    end

    for i = 1 : n10
        true_res = [true_res; L10 * data(ind : ind + 9)];
        ind = ind + 10;
    end
    
    assertElementsAlmostEqual(res, true_res, 'Results incorrect');       
    write_checksum('../log/checksum.log', 'Transform Group - Positive definite large complicated case', ...
        num2str(sum(res), '%0.5f'), num2str(mean(res), '%0.5f'));       
end

function bad_input_test

    rand('twister', 10);
    % 3 random lower triangles
    L2 = tril(rand(2, 2));
    L3 = tril(rand(3, 3));
    L4 = tril(rand(4, 4));
    
    % Symmetric positive definite matrices
    V2 = L2 * L2';
    V3 = L3 * L3';
    V4 = L4 * L4';
    
    data = rand(19, 1);
    group = [1 1 2 2 3 3 3 4 * ones(1, 4) 5 * ones(1, 4) 6 * ones(1, 4)];
    vcov = {V2, V3, V4};
    vcov_id = [1 1 2 3 3 3];
        
    assertbad( @()transform_group(vec, [group, 10, 1000], vcov, vcov_id) );
    assertbad( @()transform_group(vec, group, vcov, [vcov_id, 10]) );
end