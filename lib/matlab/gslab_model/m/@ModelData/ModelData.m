classdef (Abstract) ModelData
%
% ModelData is the abstract class for models (e.g. MleData, MdeData).
%

properties
    var = dataset()         % Dataset object to hold actual data variables
end

properties (SetAccess = protected)
    nobs                    % Number of observations in the dataset
end

properties (Dependent)
    nvars           % Number of variables
    varnames        % List of names of variables in dataset
end

methods
    function obj = ModelData(varargin)
     % Create new ModelData object
		inputlist = ModelData.ParseInputList(varargin);
        obj.var = dataset(inputlist{:});
    end

    function n = get.nobs(obj)
        n = length(obj.var);
    end

    function n = get.nvars(obj)
        n = length(obj.var.Properties.VarNames);
    end

    function list = get.varnames(obj)
        list = sort(obj.var.Properties.VarNames);
    end

    function obj = set.var(obj, value)
        obj.var = value;
        obj.nobs = length(obj.var);
        obj.var.obsindex = (1:length(obj.var))';
    end

    function bool = IsVariable(obj, varname)
        bool = any(ismember(obj.varnames, varname));
    end

    function obj = AddData(obj, varargin)
        inputlist = ModelData.ParseInputList(varargin, 1);
        newdata = dataset(inputlist{:});
        for name = newdata.Properties.VarNames
            obj.var.(name{:}) = newdata.(name{:});
        end
    end

    function obj = RemoveData(obj, varargin)
        inputlist = ModelData.ParseInputList(varargin, 1);
        for name = inputlist
            if any(strcmp(name{:},obj.varnames));
                obj.var.(name{:}) = [];
            end
        end
    end

    function obj = Select(obj, varargin)
        obj.var = obj.var(varargin{:});
    end
   
    function array = GetArray(obj, varlist)
        if nargin==1 || isempty(varlist)
            array = double(obj.var);
        else
            array = double(obj.var, varlist);
        end
    end
	
	obj = CollapseArrayVars(obj)
	obj = ExpandArrayVars(obj)
end

methods (Static, Hidden, Access = protected)
    function out = ParseInputList(list, offset)
    % This method replaces workspace variables appearing in the first part of the input list
    % with {var, 'name'} pairs. It also replaces struct inputs with {array, 'name1'} pairs
    % for each field.
        out = {};
        if nargin==1
            offset = 0;
        end
        for i = 1:length(list)
            if isnumeric(list{i}) || iscellstr(list{i})
                % Retrieve correct name of input variable from calling workspace
                inputname = evalin('caller', ['inputname (' num2str(offset+i) ')']);
                out = [out {{list{i}, inputname}}]; 
            elseif isstruct(list{i}) && ~isempty(fieldnames(list{i}))
                for name = fieldnames(list{i})'
                    out = [out {{list{i}.(name{:}) name{:}}}];
                end
            elseif ischar(list{i})
                out = [out list{i:end}];
                break;
            end
        end
    end
end

end