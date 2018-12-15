%% detectPattern: Detect Ordered Patterns
%
% detectPattern detects ordered patterns in variable names
%
% P = detectPattern(V) uses variable names V to find patterns, which are
% returned as a cell array of cell arrays in P.
%
% P = detectPattern(V, N) does the same as above, but only returns chains
% that are at least N elements long
%
%%% Remarks
%
% detectPattern returns a cell array of cell arrays in case there is more
% than one pattern.
%
% detectPattern matches ordered variables. An ordered variable is defined
% as a set of variables that have the exact same name, save for a constant
% increasing numeric identifier. For example, "num1, num2, num3, ...".
%
% While theoretically a variable could appear in multiple sets (i.e., there
% is no arbitrary restriction on the number of times a variable appears in
% the output), this cannot happen, because a variable that matches two
% patterns would mean that all variables of both patterns would match each
% other.
%
% detectPattern matches regardless of how the number is formatted. However,
% the formatting must be consistent - the number of leading zeros (if any)
% must not change
function ordered = detectPattern(vars, chainLength)
    if nargin < 2
        chainLength = 2;
    end
    vars = unique(vars);
    
    % get rid of any variables that do not have number
    mask = ~cellfun(@isempty, regexp(vars, '\d'));
    vars = vars(mask);
    
    % Break all variables into pattern:
    %   PREFIX ## SUFFIX
    tokens = regexp(vars, '(\w+)(\d)(\w*)', 'tokens');
    tokens = [tokens{:}];
    tokens = [tokens{:}];
    prefix = string(tokens(1:3:end));
    counterStrings = string(tokens(2:3:end));
    counter = cellfun(@str2double, tokens(2:3:end));
    
    suffix = string(tokens(3:3:end));
    
    % for each prefix-suffix pair, see who else matches it. If anyone else,
    % that's a list!
    bases = prefix + suffix;
    pairs = unique(bases);
    ordered = cell(1, 5);
    ind = 1;
    for p = 1:numel(pairs)
        % see who in bases match
        mask = strcmp(pairs(p), bases);
        if sum(mask) >= chainLength
            % possible list. We need to make sure that the counters match
            counters = counter(mask);
            if all(ismember(1:sum(mask), counters))
                % list!
                listVarNames = prefix(mask) + counterStrings(mask) + suffix(mask);
                ordered{ind} = cellstr(listVarNames);
                ind = ind + 1;
            end
        end
    end
    ordered(ind:end) = [];
end