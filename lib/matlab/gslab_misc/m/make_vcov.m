function [out, max_abs_diff, max_rel_diff] = make_vcov(in, max_iter)
    if nargin < 2
        max_iter = 100;
    end
    
    out = in;
    iter = 1;
    while ~is_vcov(out) && iter <= max_iter
        if asymmetric(out)
            out = (out + out')/2;
        end
        if neg_eig(out)
            [eigvec, eigval] = eig(out); 
            eigval(eigval < 0) = 0; 
            out = eigvec * eigval * eigvec';
        end
        iter = iter + 1;
    end
    
    if iter == max_iter
        fprintf('max_iter reached: %i', int2str(max_iter))
    end
    
    diff = in - out;
    
    rel_diff_mat = diff ./in;
    
    max_abs_diff = max(max(abs(diff)));
    max_rel_diff = max(max(abs(rel_diff_mat(isfinite(rel_diff_mat)))));
end

function bool = is_vcov (in)
    bool = ~asymmetric(in) * ~neg_eig(in);
end

function bool = asymmetric (in)
    bool = ~all(all(in == in'));
end

function bool = neg_eig (in)
    bool = min(eig(in)) < 0;
end