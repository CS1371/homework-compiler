classdef TestCase
    %% TestCase Represent a complete test case for a problem
    %
    % A TestCase instance contains just the information the user has
    % entered to define a test case. This is primarily the list of variable
    % names entered in the test case values panel.
    
    properties
        inputNames cell
    end
    
    methods
        function verify(this)
            cmdWinVars = evalin('base', 'whos');
        end
    end
end

