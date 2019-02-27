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
    % or no outputs
    % get outputs
    % if no [], no outputs!
    if ~contains(studCall, ']')
        % doesn't have outputs
        ins = studCall(strfind(studCall, '(') + 1:strfind(studCall, ')') - 1);
        call = studCall(1:strfind(studCall, '(') - 1);
        solnCall = [call '_soln(' ins ')'];
    else
       outs = studCall(2:strfind(studCall, ']') - 1);
        ins = studCall(strfind(studCall, '(') + 1:strfind(studCall, ')') - 1);
        call = studCall(strfind(studCall, '=') + 2:strfind(studCall, '(') - 1);
        outs = strsplit(outs, ', ');
        outs = [strjoin(outs, '_soln, ') '_soln'];
        solnCall = ['[' outs '] = ' call '_soln(' ins ')']; 
    end
end