%% getParentFigure
%
% Gets the parent UIfigure object of a child element.
function p = getParentFigure(elem)
try
    if isa(elem, 'matlab.ui.Figure') || ~isprop(elem, 'Parent')
        p = elem;
    else
        p = getParentFigure(elem.Parent);
    end
catch
    % TODO: do this better
    p = [];
end

end
