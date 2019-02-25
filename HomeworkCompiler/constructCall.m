%% constructCall: Compile into a single function call
%
% F = constructCall(N, I, O) will turn function name N, Inputs I, and
% Outputs O into function call F.
%
function call = constructCall(name, ins, outs)
    if ~iscell(outs) && isempty(outs)
        call = [name '(' strjoin(ins, ', ') ')'];
        return;
    elseif ~iscell(outs)
        outs = {outs};
    end
    call = ['[' strjoin(outs, ', ') '] = ' name '(' strjoin(ins, ', ') ')'];
end