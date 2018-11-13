%% createInputs: Creates input MAT file in current directory
%
% createInputs will create a MAT file with the right inputs defined. It
% will be called inputs.mat.
%
% createInputs(N, V) will use names N and values V to create input mat
% file.
%
function createInputs(names, values) %#ok<INUSD>
    for i = 1:numel(names)
%         for j = 1:numel(names{i})
            eval([names{i} ' = values{i};']);
%         end
    end
    
    save('inputs.mat', names{:});
end