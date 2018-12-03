%% abbreviate Abbreviates a string to a maximum length
function [newstr] = abbreviate(str, maxLength)
    if length(str) <= maxLength
        newstr = str;
    else
        newstr = str(end - maxLength+4:end);
        newstr = ['...', newstr];
    end
end

