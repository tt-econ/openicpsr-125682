function phess = GetPartialHessian(obj, rowparamlist, colparamlist)
%
% Returns partial Hessian of likelihood with respect to specified parameters.
%
% INPUTS
%
%    - rowparamlist: Cell array of names of parameters.
%    - colparamlist: Cell array of names of parameters.
%
% OUTPUTS
%
%    - phess: Hessian with rows corresponding to rowparamlist and columns corresponding to colparamlist.
%

 assert(isequal(length(rowparamlist), length(unique(rowparamlist))));
 assert(isequal(length(colparamlist), length(unique(colparamlist))));

 [rowcheck,rowindex] = ismember(rowparamlist, obj.model.paramlist);
 [colcheck,colindex] = ismember(colparamlist, obj.model.paramlist);
 
 assert(isequal(rowcheck,ones(size(rowcheck))));
 assert(isequal(colcheck,ones(size(colcheck))));
  
 phess = obj.hessian(rowindex, colindex);

end