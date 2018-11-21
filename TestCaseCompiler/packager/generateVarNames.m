%% generateVarNames: Generates variable names for use by the packager
%
% Generates variable names using a base and the number of arguments, as
% well as the desired number of test cases
%
% N = generateVarNames(B, A, T) will use base B with number of arguments A
% and number of test cases T to create cell array N.
%
function names = generateVarNames(base, narg, num)
    % if in is just one character vector / scalar string, then just check
    if (isstring(base) && isscalar(base)) || ischar(base)
        base = char(base);
        if ~isvarname(base)
            throw(MException('TESTCASE:packager:package:invalidVariableName', ...
                '"%s" is not a valid variable base name', base));
        end
    elseif numel(base) == narg && (isstring(base) || (iscell(base) && all(cellfun(@ischar, base))))
        base = cellstr(base);
        mask = ~cellfun(@isvarname, base);
        if any(mask)
            throw(MException('TESTCASE:packager:package:invalidVariableName', ...
                '"%s" is not a valid variable base name', base{find(mask, 1)}));
        end
    end
    
    % if char, then just make narg * num times
    if ischar(base)
        names = cellstr(compose("%s%d", base, 1:(narg * num)));
    else
        names = cell(1, num * narg);
        for i = 1:narg
            names(i:narg:end) = cellstr(compose("%s%d", base{i}, 1:num));
        end
    end
end