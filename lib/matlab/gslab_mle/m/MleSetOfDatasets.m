classdef MleSetOfDatasets
%
% MleSetOfDatasets holds an array of MleData objects.
%

properties
    datasets       % Cell array of MleData objects
end

properties (Dependent = true)
    ndatasets       % number of datasets
end


methods
    function obj = MleSetOfDatasets(datasets)
        if nargin>0
            obj.datasets = datasets;
        end
    end
    
    function ndatasets = get.ndatasets(obj)
        ndatasets = length(obj.datasets);
    end
    
    function SaveToDisk( obj, directory, name, precision, varargin )
        % 
        % SaveToDisk loops over data in an MleSetOfDatasets object, storing data
        % for each according to the SaveToDisk method of MleData.
        
        % INPUTS
        %    - directory: location where files will be stored        
        %    - name: name of the files to be stored
        %    - precision: number of decimal places to store for all inputs
        %    - indices: Positional indices of the datasets to save
        %
        
        if nargin < 4
            precision = 4;
        end
        
        if isempty(varargin)
            indices = 1:obj.ndatasets;
        else
            indices = varargin{:};
        end
        
        for i=indices
            obj.datasets{i}.SaveToDisk(directory, strcat(name, '_', num2str(i)), precision);
        end
    end

    function SaveToDiskNative( obj, directory, name, varargin )
        % 
        % SaveToDiskNative loops over data in an MleSetOfDatasets object, storing data
        % for each according to the SaveToDiskNative method of MleData (note that is slower,
        % but larger precision on some variables without taking up space for all variables.)        

        % INPUTS
        %    - directory: location where files will be stored        
        %    - name: name of the files to be stored
        %    - indices: Positional indices of the datasets to save
        %
        
        if isempty(varargin)
            indices = 1:obj.ndatasets;
        else
            indices = varargin{:};
        end
        
        for i=indices
            obj.datasets{i}.SaveToDiskNative(directory, strcat(name, '_', num2str(i)));
        end
    end
    
    function obj = LoadFromDisk( obj, directory, name, indices )
        % 
        % LoadFromDisk creates a MleSetOfDatasets object by looping over stored data
        % according to the LoadFromDisk method of MleData.
        
        % INPUTS
        %    - directory: location where files will be stored        
        %    - name: name of the files to be stored
        %    - indices: Positional indices of the datasets to save
        %
        if size(indices) == 1
            indices = [1:indices];
            
        end
        for i=indices
            obj.datasets{i} = MleData;
            obj.datasets{i} = obj.datasets{i}.LoadFromDisk(directory, strcat(name, '_', num2str(i)));
        end
    end
    
end


end
