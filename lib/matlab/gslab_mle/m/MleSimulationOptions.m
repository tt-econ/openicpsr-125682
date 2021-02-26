classdef MleSimulationOptions
%
% MleSimulationOptions defines options for the Simulate() method of
% MleModel.
%

properties
    seed                   = 0     % Seed for the random number generator.
    replications           = 1      % Number of simulation replications to produce
end

methods
    function obj = MleSimulationOptions(varargin)
        if nargin > 0
            obj = obj.AssignOptions(varargin{:});
        end
    end
end

methods (Hidden, Access = protected)
    function obj = AssignOptions(obj, varargin)
        option_struct = parse_option_list(varargin{:});
        for field = fieldnames(option_struct)'
            obj.(field{:}) = option_struct.(field{:});
        end
    end
end

end
