%% checkRecur: Check if a function is recursive
%
% checkRecur will check code to ensure that it is recursive.
%
% I = checkRecur(F) will function path F to check if F is recursive. F must
% be an absolute path
%
%%% Remarks
%
% Recursion comes in two flavors: Direct and Mutual
%
% Direct recursion means that a function just calls itself; function A
% calls function A. This is the simplest form of recursion.
%
% Mutual recursion means that a function calls another function, which then
% eventually calls the original function. Function A calls function B,
% which turns around and calls function A. This is still recursion, and
% where the stack comes into play.
%
% checkRecur uses static analysis, served up via getcallinfo. While this
% does mean it can be quite performant, it also means that it can be
% tricked. For example, consider the following code:
%
%   function out = notRecur(in)
%       if false
%           out = notRecur(in);
%       end
%   end
%
% Though statically, it appears that notRecur calls itself, in reality that
% code is never run, because false is never true. However, checkRecur will
% still return true.
function isRecurring = checkRecur(functionPath)
    % Check if this function calls itself. If so, exit true.
    % If not, check all functions it calls:
    %   If the call is to a builtin, don't investigate
    %   If the call is to something NOT builtin, investigate!
    % Investigating means calling ourself recursively.
    %
    % Checking for mutual recursion:
    %   To check for mutual recursion, each call, if it calls something in
    %   the stack, then exit true.
    %   For example:
    %       a -> b -> c -> b
    %       a: stack is {}
    %       b: stack is {'a'}
    %       c: stack is {'a', 'b'};
    %       b: stack is {'a', 'b', 'c'};
    %       @ a->b->c->b, 'b' is current name AND in stack, so return true!
    [path, main, ~] = fileparts(functionPath);
    try
        callInfo = getcallinfo(functionPath);
        isRecurring = recursiveChecker(callInfo, main, path, {});
    catch
        isRecurring = false;
    end
end

function isRecurring = recursiveChecker(callInfo, main, path, stack)

    % First, check calls for itself.
    mainCall = callInfo(strcmp({callInfo.name}, main));
    if any(strcmp(mainCall.name, mainCall.calls.innerCalls.names))
        % true. Exit
        isRecurring = true;
        return;
    end

    % if the stack ~isempty, then check ourselves on the stack.
    if ~isempty(stack) && any(strcmp(stack, main))
        isRecurring = true;
        return;
    else
        stack = [stack {main}];
    end
    % look at all functions in callInfo that aren't us but that we call
    % (innerCalls, excluding ourselves)
    calls = callInfo(~strcmp({callInfo.name}, main));
    calls = calls(ismember({calls.name}, mainCall.calls.innerCalls.names));
    for i = 1:numel(calls)
        if recursiveChecker(callInfo, calls(i).name, path, stack)
            isRecurring = true;
            return;
        end
    end

    % Iterate over internal calls, checking the stack
    internal = mainCall.calls.innerCalls.names;
    for i = 1:numel(internal)
        if any(strcmp(stack, internal{i}))
            isRecurring = true;
            return;
        end
    end
    % Iterate over external calls.
    external = mainCall.calls.fcnCalls.names;
    % check local directory for filenames. If not there, builtin!
    possCalls = dir([path filesep '*.m']);
    possCalls = cellfun(@(n)(n(1:(end-2))), {possCalls.name}, 'uni', false);
    for i = 1:numel(external)
        % if external isn't found anywhere in possCalls, don't engage
        if any(strcmp(external{i}, possCalls))
            extCallInfo = getcallinfo([path filesep external{i} '.m']);
            if recursiveChecker(extCallInfo, external{i}, path, stack)
                isRecurring = true;
                return;
            end
        end
    end

    isRecurring = false;
end