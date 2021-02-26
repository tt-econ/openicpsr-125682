function [void] = dlmwrite_fast(filename,matrix,varargin)
% This function calls a fast version of the dlmwrite function re-written in C.
%
% USAGE: 
% dlmwrite_fast(filename,matrix,delimiter,mode,header,precision); 
% (arguments will be parsed in the order as defined here)
% OR:
% dlmwrite_fast(filename,matrix,'delimiter',delimiter,'mode',mode,'header',header,'NaN',char_nan,'Inf',char_inf,'precision',precision);
% (the optional arguments will be parsed as the specified input)
%
% The option 'NaN' specifies how you would like values of "NaN" to be
% printed to the output file, and similiarly for the option 'Inf'. 
%
% The option 'precision' specifies the number of digits printed after the
% decimal point. By default, it is set to 4.
%
% Basically, the filename and matrix arguments are required, and for the
% optional arguments, we have the freedom of doing two type of inputs.
% For the first type, inputs have to be in the order of "delimiter,
% mode, header", in which case writing "dlmwrite_fast('a.csv',m,'1','a')"
% is equivalent to telling the function that the delimiter is '1', and the
% mode is 'a', with no header.
% For the second type, the user has the freedom of choosing which optional 
% arguments to specify, and the order of specification. They, however, need 
% to put a string to specify what the following value is for, before specifying the 
% values.
% Example: 
% header = {'var1','var2','var3'};
% dlmwrite_fast('a.csv',m,'header',header,'delimiter','.','NaN','NaN','Inf','Inf');
% (no mode specified - 'w' assumed by default)
%
%
% NOTE: 
% 1. The input matrix can be the following types: single, double, int8, int16, int32.
% 2. If the input matrix is of type "single" or "double", then the output file will have a bunch of trailing decimal 0's;
%               hence if you want to output integers, it's better to
%               convert the matrix to integer types first, by using the
%               following command:
%
%               "matrix = int32(matrix)".
%
%
%
% "filename" is the path and name of the output file,
% "matrix" is the 2 dimensional matrix that we want to print to file.
% "delimiter" is the delimiter we want to use for the matrix elements,
% "mode" can be "w" which means "write" (overwrite if already exists), or
%               "a" which means "append" (create a new file if doesn't already exist).
% "header" has to be a cell array of dimension 1 by n, where n is the
%               number of columns of the matrix to be printed. Each element
%               of the header cell array has to be string.
%
%
%
% "delimiter", "mode", and "header" are optional - "delimiter" is set to "," by default, and the default "mode" is "w".
%               By default, there is no header.
%
% For example, if "a = [1 2 3;4 5 6]", then "dlmwrite_fast('./output.csv',a,',','w')" 
% will produce (and overwrite if it already exists) "output.csv" in the current folder:
%
% 1,2,3
% 4,5,6
%
%
%
    if (strcmp(class(matrix),'int8') || (strcmp(class(matrix),'int16')))
        matrix = int32(matrix);
    elseif (isreal(matrix)==0)
        error('The function can only handle matrices with real numbers...');
    end;
    
    if ndims(matrix)>2
        error('The function only supports matrices of two dimensions');
    end;
    
    if nargin <2
        error('At least two input arguments required.');
    end;
    
    [dlm,mode,header,char_nan,char_inf,prec] = parseinput(length(varargin),varargin);
    if ~strcmp(mode,'a') && ~strcmp(mode,'w')
        error('Only write (w) mode and append (a) mode are supported');
    end
    if ~iscell(header)
        %fprintf('No header specified; to include a header, please create a cell array and write the variable names as cell elements');
        dlmwrite_c(filename,matrix,dlm,mode,char_nan,char_inf,prec);
        fprintf('Writing %s to disk...',filename);
    else
        if ndims(header)>2
            error('The header cell array must be a row vector with length equal to the number of elements in a row');
        elseif size(header,1)>1
            error('The header cell array must be a row vector with length equal to the number of elements in a row');
        elseif size(header,2)~=size(matrix,2)
            error('The header cell array must be a row vector with length equal to the number of elements in a row');
        end
        
        fID = fopen(filename, mode);
        for i=1:(size(header,2)-1)
            if ~ischar(header{i})
                error('The header cell array must contain only strings');
            end
            fprintf(fID,'%s%s',header{i},dlm);
        end
        fprintf(fID,'%s\n',header{size(header,2)});

        fclose(fID);
        fprintf('Writing %s to disk...',filename);
        dlmwrite_c(filename,matrix,dlm,'a',char_nan,char_inf,prec);
    end;
    clear dlmwrite_c;
    fprintf('\n');
end

function [dlm,m,h,char_nan,char_inf,prec] = parseinput(options,varargin)

% initialise parameters
dlm = ',';
m = 'w';
h = '';
char_nan = 'NaN';
char_inf = 'Inf';
prec = int64(4);

if options > 0
    % define input attribute strings
    delimiter = 'delimiter';
    mode = 'mode';
    header = 'header';
    cnan = 'nan';
    cinf = 'inf';
    precision = 'precision';
    attributes = {delimiter,mode,header,cnan,cinf,precision};

    varargin = varargin{:}; % extract cell array input from varargin

    % test whether attribute-value pairs are specified, or fixed parameter order
    stringoptions = lower(varargin(cellfun('isclass',varargin,'char')));
    attributeindexesinoptionlist = ismember(stringoptions,attributes);
    newinputform = any(attributeindexesinoptionlist);
    if newinputform
        % parse values to functions parameters
        i = 1;
        while (i <= length(varargin))
            %Check to make sure that there is a pair to go with
            %this argument.
            if length(varargin) < i + 1
                error('MATLAB:dlmwrite:AttributeList', ...
                    'Attribute %s requires a matching value', varargin{i})
            end
            if strcmpi(varargin{i},delimiter)
                dlm = varargin{i+1};
            elseif strcmpi(varargin{i},mode)
                m = varargin{i+1};
            elseif strcmpi(varargin{i},header)
                h = varargin{i+1};
            elseif strcmpi(varargin{i},cnan)
                char_nan = varargin{i+1};
            elseif strcmpi(varargin{i},cinf)
                char_inf = varargin{i+1};
            elseif strcmpi(varargin{i},precision)
                if int32(varargin{i+1})==varargin{i+1}
                    prec = int64(varargin{i+1});
                else
                    warning('The precision input is not an integer; set to 4 by default',precision);
                    prec = int64(4);
                end
            else
                error('MATLAB:dlmwrite:Attribute',...
                    'Invalid attribute tag: %s', varargin{i})
            end
            i = i+2;
        end
    else % arguments are in fixed parameter order
        % delimiter defaults to Comma for CSV
        if options > 0
            dlm = varargin{1};
        end

        % row and column offsets defaults to zero
        if options > 1 && ~isempty(varargin{2})
            m = varargin{2};
        end
        if options > 2 && ~isempty(varargin{3})
            h = varargin{3};
        end
    end
end
end

