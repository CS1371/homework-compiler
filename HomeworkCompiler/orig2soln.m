%% orig2soln: Converts the original call to a solution call
%
% orig2soln will convert a call to a call to the solution file.
%
% S = orig2soln(C) will convert call C to solution call S.
%
%%% Remarks
%
% It is assumed that the original call will ALWAYS be of the form:
%
%   [OUTPUT1, OUTPUT2, ...] = call(IN1, IN2, ...)
function solnCall = orig2soln(studCall)
    % will ALWAYS be of form:
    % [OUTPUT1, OUTPUT2, ...] = call(IN1, IN2, ...)
    
    % get outputs
    outs = studCall(2:strfind(studCall, ']') - 1);
    ins = studCall(strfind(studCall, '(') + 1:strfind(studCall, ')') - 1);
    call = studCall(strfind(studCall, '=') + 2:strfind(studCall, '(') - 1);
    if ~isempty(outs)
        outs = strsplit(outs, ', ');
        outs = [strjoin(outs, '_soln, ') '_soln'];
    end
    solnCall = ['[' outs '] = ' call '(' ins ')'];
end