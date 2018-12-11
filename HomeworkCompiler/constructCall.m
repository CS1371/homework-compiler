%% constructCall: Compile into a single function call
%
% F = constructCall(N, I, O) will turn function name N, Inputs I, and
% Outputs O into function call F.
%
function call = constructCall(name, ins, outs)
    call = ['[' strjoin(outs, ', ') '] = ' name '(' strjoin(ins, ', ') ');'];
end
