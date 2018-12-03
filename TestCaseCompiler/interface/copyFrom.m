%% copyFrom Copy fields from one object to another
%
% copyFrom(T, F, FIELDS) copies field names from cell array FIELDS from
% object F to object T.
function copyFrom(to, from, fields)
    for x = 1:length(fields)
        if isprop(to, fields{x}) && isfield(from, fields{x})
            to.(fields{x}) = from.(fields{x});
        end
    end
end
