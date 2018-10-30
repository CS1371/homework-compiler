classdef TestCase < handle
    %% TestCase Represent a complete test case for a problem
    %
    % A TestCase instance contains just the information the user has
    % entered to define a test case. This is primarily the list of variable
    % names entered in the test case values panel.
    
    %% Non-UI properties
    properties
        % names of input variables, as selected by user in the UI
        InputNames cell
        
        % index of this test case
        Index double
        
        % Submission type this test case belongs to
        ParentType SubmissionType
    end
    
    %% UI properties
    % This section contains all properties (UI-specific) that represent
    % objects that are generated upon creation of a new test case.
    properties (SetAccess = private)
        % The tab object itself
        Tab matlab.ui.container.Tab
        
        % Parent tab container
        Parent matlab.ui.container.TabGroup
        
        
    end
    
    properties
        % Comma labels to separate outputs in the preview
        OutCommas matlab.ui.control.Label
        
        % Comma labels for inputs
        InCommas matlab.ui.control.Label
        
        % Drop-down boxes for the input values selector
        InputDropdowns matlab.ui.control.DropDown
        
        % Components of the function preview
        LeftOutBracket matlab.ui.control.Label
        RightOutBracket matlab.ui.control.Label
        FunctionName matlab.ui.control.Label
        RightInputParen matlab.ui.control.Label
    end
    
    properties (Constant)
        %% Constants for the function call display %%
        CHAR_WIDTH = 7.25;
        BOXES_PER_LINE = 3;
        VERTICAL_SPACER = 2;
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
        function this = TestCase(parent, subType)
            this.Parent = parent;
            this.Tab = uitab(parent);
            this.ParentType = subType;
            this.Index = length(this.ParentType.TestCases) + 1;
            this.Tab.Title = sprintf('Test Case %d', this.Index);
            
            % populate with the function preview
            % Create LeftOutBracket
            this.LeftOutBracket = uilabel(this.Tab);
            this.LeftOutBracket.FontName = 'Courier New';
            this.LeftOutBracket.Position = [235 16 10 22];
            this.LeftOutBracket.Text = '[';
            
            % Create RightInputParen
            this.RightInputParen = uilabel(this.Tab);
            this.RightInputParen.FontName = 'Courier New';
            this.RightInputParen.Position = [342 16 10 22];
            this.RightInputParen.Text = ')';
            
            % Create FunctionName
            this.FunctionName = uilabel(this.Tab);
            this.FunctionName.FontName = 'Courier New';
            this.FunctionName.Position = [287 16 49 22];
            this.FunctionName.Text = '= %s(';
            
            % Create RightOutBracket
            this.RightOutBracket = uilabel(this.Tab);
            this.RightOutBracket.FontName = 'Courier New';
            this.RightOutBracket.Position = [263 16 10 22];
            this.RightOutBracket.Text = ']';
            
            redrawFunctionPreview(this);
            
        end
        
        %% deleteTestCase Deletes this test case
        %
        % Deletes this test case object by removing the associated tab
        % object.
        %
        % Called by SubmissionType's deleteTestCase, which is called by the
        % UI when a test case is removed.
        function deleteTestCase(this)
            delete(this.Tab);
        end
        
        %% set.Index
        %
        % Sets the index of this test case and sets the tab title
        % accordingly.
        function set.Index(this, value)
            this.Index = value;
            this.Tab.Title = ['Test Case ', num2str(value)];
        end
        
        %% redrawFunctionPreview
        %
        % Redraws the function preview in the test case input value editor.
        %
        function redrawFunctionPreview(this)            
%             if isempty(app.outBase) || isempty(app.outBase{1})
%                 % set base words to auto if none specified
%                 app.outBase = {'out'};
%             end
            
%             app.outputNames.(subType) = generateVarNames(app.outBase, app.numOutputs, app.numTestCases.(subType));

            addFunctionNamePreview(this);
            addOutputNameEditFields(this);
            addInputNameEditFields(this);
        end

    end
    
    methods (Access = private)
        function addOutputNameEditFields(this)
            value = this.ParentType.Problem.NumOutputs;
            CUSTOM_WIDTH = 8;
            % do separate things if auto or not
            % if auto, always out#
            % otherwise, length of each tb? -> 8 chars
            % create var names
            
            if ~isempty(this.OutCommas)
                delete(this.OutCommas);
            end
            
            this.LeftOutBracket.Text = '[';
            
            if value > 0
                % create out names
                %                 nums = arrayfun(@num2str, 1:value, 'uni', false);
                %                 [base{1:value}] = deal('out');
                %                 vars = ['[' strjoin(join([base; nums]', ''), ', ') ']'];
%                 vars = app.outputNames.(subType)(1:app.numOutputs);
                vars = this.ParentType.OutputNames;
                vars = ['[', strjoin(vars, ','), ']'];
                this.RightOutBracket.Visible = false;
                posn = this.LeftOutBracket.Position;
                this.LeftOutBracket.Position = [...
                    this.FunctionName.Position(1) - (this.CHAR_WIDTH * length(vars)), ...
                    posn(2), this.CHAR_WIDTH * length(vars), posn(4)];
                this.LeftOutBracket.Text = vars;
            else
                this.RightOutBracket.Position = [this.FunctionName.Position(1:2), app.CHAR_WIDTH, ...
                    this.FunctionName.Position(4)];
                this.LeftOutBracket.Position = this.RightOutBracket.Position - [app.CHAR_WIDTH 0 0 0];
            end
            
        end
        
        %% addFunctionNamePreview
        %
        % Draws the function name in the input values editor.
        %
        function addFunctionNamePreview(this)
            FORMAT = ' = %s(';
            
            % set the value
            this.FunctionName.Text = sprintf(FORMAT, this.ParentType.Problem.FunctionName);
            % set the width correctly
            posn = this.FunctionName.Position;
            this.FunctionName.Position = [posn(1:2), ...
                this.CHAR_WIDTH * length(this.FunctionName.Text), posn(4)];
            
            % move the right paren
            posn = this.FunctionName.Position;
            this.RightInputParen.Position = [...
                this.FunctionName.Position(1) + this.FunctionName.Position(3) - 1, ...
                posn(2:end)];
            
        end
        
        %% addInputNameEditFields
        %
        % Adds the input value edit fields to the function preview.
        function addInputNameEditFields(this)
            value = this.ParentType.Problem.NumInputs;
            CUSTOM_WIDTH = 8;
            % do separate things if auto or not
            % if auto, always out#
            % otherwise, length of each tb? -> 8 chars
            % create var names
            if ~isempty(this.InputDropdowns)
                delete(this.InputDropdowns);
            end
            
            if ~isempty(this.InCommas)
                delete(this.InCommas);
            end
            this.RightInputParen.Text = ')';
            
            this.RightInputParen.Position(2) = this.FunctionName.Position(2);
            %             if app.([subType, 'AutomaticInputsCheckBox']).Value
            %                 % create out names
            % %                 nums = arrayfun(@num2str, 1:value, 'uni', false);
            % %                 [base{1:value}] = deal('in');
            % %                 vars = [strjoin(join([base; nums]', ''), ', ') ')'];
            %                 vars = app.inputNames.(subType)(1:app.numInputs);
            %                 vars = [strjoin(vars, ','), ')'];
            %                 posn = app.([subType, 'RightInputParen']).Position;
            %                 app.([subType, 'RightInputParen']).Position = [...
            %                     app.([subType, 'FunctionName']).Position(1) + app.([subType, 'FunctionName']).Position(3), ...
            %                     posn(2), app.CHAR_WIDTH * length(vars), posn(4)];
            %                 app.([subType, 'RightInputParen']).Text = vars;
            if value ~= 0
                % create array of edit fields
%                 app.inEdits.(subType) = cell(1, value);
%                 app.inCommas.(subType) = cell(1, value - 1);
                posn = this.RightInputParen.Position;
                for e = 1:numel(value)
                    if e ~= 1
                        % add comma
                        tmp = uilabel(this.Tab, 'FontName', 'Courier New', ...
                            'FontSize', 12, 'Text', ',');
                        tmp.Position = [...
                            sum(this.InputDropdowns(e - 1).Position([1 3])), posn(2), this.CHAR_WIDTH, posn(4)];
                        this.InCommas(e) = tmp;
                    end
                    tmp = uidropdown(this.Tab, 'FontName', 'Courier New', ...
                        'FontSize', 12);
                    baseVars = evalin('base', 'who');
                    tmp.Items = baseVars(~strcmp(baseVars, 'ans'));
                    if isempty(tmp.Items)
                    else
                        tmp.Value = tmp.Items{mod(e, length(tmp.Items))};
                    end
%                     tmp.ValueChangedFcn = createCallbackFcn(app, @(a, ev)(inputBaseWordEditFieldChanged(a, ev, subType, e)), true);
%                     tmp.ValueChangedFcn = @(dropDown, ev)(updateInputsList(dropDown.Value, e));
                    % depending on where we are, different. Width = 8 chars
                    tmp.Position([2 4]) = posn([2 4]);
                    tmp.Position(3) = this.CHAR_WIDTH * CUSTOM_WIDTH;
                    if e == 1
                        tmp.Position(1) = sum(this.FunctionName.Position([1 3]));
                    elseif e ~= 1 && mod(e - 1, this.BOXES_PER_LINE) == 0
                        tmp.Position(1) = sum(this.FunctionName.Position([1 3])) - this.CHAR_WIDTH;
                        tmp.Position(2) = posn(2) - posn(4) - this.VERTICAL_SPACER;
                        posn(2) = tmp.Position(2);
                    else
                        tmp.Position(1) = sum(this.InputDropdowns(e - 1).Position([1 3]));
                    end
                    if e ~= 1
                        tmp.Position(1) = tmp.Position(1) + this.CHAR_WIDTH;
                    end
                    this.InputDropdowns(e) = tmp;
                end
                %                 for e = 1:numel(app.inEdits.(subType))
                %                     app.inEdits.(subType){e}.Value = num2str(e);
                %                 end
                this.RightInputParen.Position = [sum(this.InputDropdowns(end).Position([1 3])), posn(2:end)];
            else
                this.RightInputParen.Position = [sum(this.FunctionName.Position([1 3])), ...
                    this.FunctionName.Position(2), this.CHAR_WIDTH, this.FunctionName.Position(4)];
            end
        end
        
        %% updateInputsList
        %
        % Called whenever one of the input dropdowns is changed.
        function updateInputsList(this, selectedName, ind)
            this.InputNames{ind} = selectedName;
        end
    end
end

