function dparam = DerivedParam(obj, param, constants, dparamname)
%
% Compute derived parameters. This method taks as input a model, parameter vector, and constants,
% and returns the value of the derived parameter given by dparamname. The MleModel version of this
% function simply returns an empty value. Implementing subclasses are responsible for populating
% this function to handle all deived parameters listed in the dparamlist model property.
%

switch dparamname
    case ''
        dparam = [];
end

