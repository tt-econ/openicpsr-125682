function bool = IsValidModel(obj)
%
% Determines whether a particular implementation of MleModel is valid
%

bool = true;

% all lists are cell arrays of strings that are either empty or row arrays
for listname = {'paramlist' 'indiv_unobs_list' 'group_unobs_list' 'error_list'}
    list = obj.(listname{:});
    bool = bool && iscellstr(list) && (isempty(list) || size(list,1)==1);
end

% distributions defined for each element of error_list
bool = bool && isempty( setdiff( fieldnames(obj.error_distributions), obj.error_list));