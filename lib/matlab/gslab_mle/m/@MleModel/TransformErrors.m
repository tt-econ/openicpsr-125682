function error = TransformErrors(obj, param, data, raw_error)
%     Takes as input a parameter vector, and data, and a struct of i.i.d. draws,
%     and returns a struct of errors. The input raw_error will contain a field
%     for each error, with field names matching error names. The raw errors are
%     drawn i.i.d. across observations with distributions defined by error_distributions. 
%     For vector-valued errors (dimension > 1 as defined by error_dimensions), the draws
%     are also i.i.d. across elements of the vector.
%
%     The MleModel of this method simply passes through the raw errors. Implementing subclasses will
%     typically transform the errors as a function of parameters and data.
%
%     INPUTS
%       - param: Vector of parameters at which to evaluate unobservables.
%       - data: MleData object.
%       - raw_unobs: Struct with one field for each unobservable in the model.
%
%     OUTPUTS
%       - unobs: Struct with one field for each unobservable in the model.

error = raw_error;