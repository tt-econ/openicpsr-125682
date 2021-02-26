function unobs = TransformUnobservables(obj, param, data, raw_unobs)
%     Takes as input a parameter vector, and data, and a struct of i.i.d. draws,
%     and returns a struct of unobservables. The input raw_unobs will contain a field
%     for each unobservable, with field names matching unobservable names. For group-level
%     unobservables, each field of raw_unobs contains standard normal draws at the group level, 
%     with values replicated across draws within groups. For individual-level unobservables,
%     raw_unobs contains i.i.d. standard normal draws across observations. The transformation
%     function must not exhibit dependencies across groups, nor, in the case of group-level
%     unobservables, across observations. For models with no unobservables, this
%     method can simply return an empty struct.
%
%     The MleModel of this method simply passes through the raw unobservables. Implementing 
%     subclasses will typically transform the unobservables as a function of parameters and data.
%
%     INPUTS
%       - param: Vector of parameters at which to evaluate unobservables.
%       - data: MleData object.
%       - raw_unobs: Struct with one field for each unobservable in the model.
%
%     OUTPUTS
%       - unobs: Struct with one field for each unobservable in the model.

unobs = raw_unobs;