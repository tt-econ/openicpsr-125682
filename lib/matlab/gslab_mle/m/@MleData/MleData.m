classdef MleData < ModelData
%
% MleData is the data class for MLE models.
%
% An MleData object's data is stored in the var property, which is a Matlab dataset object.
% It can have an arbitrary number of data fields. Each data field 
% must be a numeric / cell / boolean array of dimension <=2.
%
% The property var contains a vector identifying groups in the panel. This vector must be sorted in
% ascending order with length equal to the row dimension of the var property.
%
% The constructor MleData() accepts the same inputs as the constructor for the Matlab dataset class.
%
% Examples:
%    data = MleData();
%    data = MleData(x, y, z);
%    display(data.var.y);
%
%    mystruct.a = 1;
%    mystruct.b = 2;
%    data = MleData(x, mystruct);
%    display(data.var.x);
%    display(data.var.a);
%

properties
    const = struct()        % Struct to hold constants characterizing the dataset
    groupvar = []           % Variable identifying groups in panel
end

properties (SetAccess = protected)
    ngroups                 % Number of groups in panel
    group_size              % Vector of size ngroups x 1 giving number of observations in each group
    unique_group_sizes      % Unique group sizes that appear in the data
end

methods
    function obj = MleData(varargin)
		inputlist = ModelData.ParseInputList(varargin);
        obj.var = dataset(inputlist{:});
	end

    function obj = set.groupvar(obj, value)
        obj.groupvar = value;
        obj.ngroups = length(unique(obj.groupvar));
        obj.group_size = sumwithin(ones(obj.nobs,1), obj.groupvar);
        obj.unique_group_sizes = unique(obj.group_size);
        obj.AssertValidGroupVar;
    end

    function obj = Select(obj, varargin)
        obj.var = obj.var(varargin{:});
        obj.groupvar = obj.groupvar(varargin{1});
    end
end

methods (Hidden, Access = protected)
    function AssertValidGroupVar(obj)
        if ~isempty(obj.groupvar)
            assert(all( obj.groupvar(2:end) - obj.groupvar(1:end-1) >= 0 ),...
                'Group variable not sorted');
            assert(isequal(length(obj.groupvar), obj.nobs),... 
                'Length of groupvar does not match data');
        end
    end
end

end