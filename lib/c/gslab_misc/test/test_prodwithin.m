function test_prodwithin
%
% Unit tests for prodwithin mex function
%

addpath(genpath('../external'))
addpath(genpath('../mex'))

% repeatedly call mex functions to make sure there is no segmentation error
for i=1:1000
    vin_1 = [1 2 3 4; 5 6 7 8];
    [vout1,grpout1] = prodwithin(vin_1,[1;1]);
    [vout2,grpout2] = prodwithin(vin_1,[2;1]);
    vin_2 = [1 2; 3 4; 5 6; 7 8];
    [vout3,grpout3] = prodwithin(vin_2,[2;1;1;1]);
    [vout4,grpout4] = prodwithin(vin_2,[3;2;1;4]);
end

% Good cases
assert( isequal(vout1, [5 12 21 32]) );
assert( isequal(vout2, [5 6 7 8; 1 2 3 4]) );
assert( isequal(vout3, [105 192; 1 2]) );
assert( isequal(vout4, [5 6; 3 4; 1 2; 7 8]) );
assert( isequal(grpout1, [1]) );
assert( isequal(grpout2, [1;2]) );
assert( isequal(grpout3, [1;2]) );
assert( isequal(grpout4, [1;2;3;4]) );

% Bad cases
assertbad( @()prodwithin(x1,1) );
assertbad( @()prodwithin(x1,[1 1]) );


