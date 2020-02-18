%% constructCheck: 
%
% F = constructCheck(O) will turn a cell array of outputs O into an
% isequal call
% 
% ex:   F = constructCheck({'velocity', 'acceleration'})
%       F => ['isequal(velocity, velocity_soln) & isequal(acceleration,' ...
%           'acceleration_soln)']
%
function check = constructCheck(outs)
check = cell(1, numel(outs));
if ~iscell(outs)
    outs = {outs};
end
for o = 1:numel(outs)
    check{o} = ['isequal(' outs{o} ', ' outs{o} '_soln)'];
end
check = strjoin(check, ' & ');
end



