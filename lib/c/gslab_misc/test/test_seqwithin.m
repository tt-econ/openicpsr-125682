function test_seqwithin
%
% Unit tests for seqwithin mex function
%

addpath(genpath('../external'))
addpath(genpath('../mex'))

% repeatedly call mex functions to make sure there is no segmentation error
for i=1:1000
    [vout1,grpout1] = seqwithin([1;1]);
    [vout2,grpout2] = seqwithin([2;1]);
    [vout3,grpout3] = seqwithin([2;1;1;1]);
    [vout4,grpout4] = seqwithin([3;2;1;4]);
end

% Good cases
assert( isequal(vout1, [1;2]) );
assert( isequal(vout2, [1;1]) );
assert( isequal(vout3, [1;2;3;1]) );
assert( isequal(vout4, [1;1;1;1]) );
assert( isequal(grpout1, [1;1]) );
assert( isequal(grpout2, [1;2]) );
assert( isequal(grpout3, [1;1;1;2]) );
assert( isequal(grpout4, [1;2;3;4]) );

% Bad cases
assertbad( @()seqwithin([1;1],[1;1]) );


