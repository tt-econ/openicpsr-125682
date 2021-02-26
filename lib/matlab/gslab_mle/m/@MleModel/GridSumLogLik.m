function [grid likelihood] = GridSumLogLik(obj, baseparam, data, paramnames, gv)
%
% Returns sum of log likelihood evaluated on a one- or two-dimensional parameter
% grid. Can be used as a plotting utility.
%
% INPUTS
%   - baseparam: Parameter vector defining point values for all parameters.
%   - data: An MleData object.
%   - paramnames: Cell array of one or two parameter names.
%   - gv: Array/cell array of grid vectors for parameters in paramlist.
%
% OUTPUTS
%   - grid: Array/cell array of grid values for parameters in paramnames.
%   - likelihood: Array of likelihood values evaluated at grid points.
%

assert(length(paramnames)==2|length(paramnames)==1);
if length(paramnames)==2
    [grid likelihood] = grid_twoparam(obj, baseparam, data, paramnames, gv);
elseif length(paramnames)==1
    [grid likelihood] = grid_oneparam(obj, baseparam, data, paramnames, gv);
end

    function [grid likelihood] = grid_twoparam(obj, baseparam, data, paramnames, gv)
    grid = cell(1, 2);
    [grid{1}, grid{2}] = meshgrid(gv{1}, gv{2});
    assert(isequal(size(grid{1}), size(grid{2})));
    likelihood = zeros(size(grid{1}));
    [I J] = size(likelihood);
    for i=1:I
        for j=1:J
            param = baseparam;
            param(obj.indices.(paramnames{1})) = grid{1}(i,j);
            param(obj.indices.(paramnames{2})) = grid{2}(i,j);
            likelihood(i,j) = obj.GetSumLogLik(param, data);
        end
    end
    end

    function [grid likelihood] = grid_oneparam(obj, baseparam, data, paramnames, gv)
    grid = gv;
    likelihood = zeros(size(grid));
    for i=1:length(likelihood)
            param = baseparam;
            param(obj.indices.(paramnames{1})) = grid(i);
            likelihood(i) = obj.GetSumLogLik(param, data);
    end
    end
end