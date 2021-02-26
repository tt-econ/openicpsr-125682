function test_make_vcov
    rng(123);

    num_tests = 20;
    max_diff = zeros(num_tests, 1);    
    mat_size = 15;
    eta = 10^-6;
    for i = 1:num_tests
        a = example_matrix(mat_size, eta);
		assert(min(eig(a)) < 0);
		
        [b, max_abs_diff, max_rel_diff] = make_vcov(a);
        max_diff(i) = max_abs_diff;
        
        assert(all(all(b == b')));
        assert(min(eig(b)) >= 0);
    end
    assert(max(max_diff) < (eta * 10));
    
    load ./input/make_vcov_test_matrices.mat
    
	assert(~all(all(test1 == test1')));
    [test1_vcov, test1_max_abs_diff] = make_vcov(test1);
    assert(all(all(test1_vcov == test1_vcov')));
    assert(min(eig(test1_vcov)) >= 0);

	assert(~all(all(test2 == test2')));
    [test2_vcov, test2_max_abs_diff] = make_vcov(test2);
    assert(all(all(test2_vcov == test2_vcov')));
    assert(min(eig(test2_vcov)) >= 0);
end

function a = example_matrix(size, eta)
    a = rand(size);
    a = triu(a) + triu(a)';
    step = min(eig(a)) + eta;
    a = a - step * eye(size);
end