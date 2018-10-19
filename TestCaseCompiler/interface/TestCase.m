classdef TestCase
    %% TestCase Represent a complete test case for a problem
    %
    % A TestCase instance contains just the information the user has
    % entered to define a test case. This is primarily the list of variable
    % names entered in the test case values panel.
    
    %% Non-UI properties
    properties
        % names of input variables, as selected by user in the UI
        inputNames cell
    end
    
    %% UI properties
    % This section contains all properties (UI-specific) that represent
    % objects that are generated upon creation of a new test case.
    properties (SetAccess = private)
        % The tab object itself
        Tab matlab.ui.container.Tab
        
        % Parent tab container
        Parent matlab.ui.container.TabGroup
        
        % Components of the function preview
        LeftOutBracket matlab.ui.control.Label
        RightOutBracket matlab.ui.control.Label
        FunctionName matlab.ui.control.Label
        RightInputParen matlab.ui.control.Label
        
    end
    
    %% Private properties
    properties (Access = private)
        % actual values, not loaded until test case export
        inputValues cell
    end
    
    methods
        %% TestCase Create a new test case object
        %
        % THIS = TestCase(P) creates a new test case object with parent
        % tabgroup P.
        function this = TestCase(parent)
            this.Parent = parent;
        end
        
        function verify(this)
            cmdWinVars = evalin('base', 'whos');
        end
    end
end

