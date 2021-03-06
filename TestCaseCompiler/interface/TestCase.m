classdef TestCase < handle
    %% TestCase Represent a complete test case for a problem
    %
    % A TestCase instance contains just the information the user has
    % entered to define a test case. This is primarily the list of variable
    % names entered in the test case values panel.
    %
    % (c) 2018 CS1371 (J. Htay, D. Profili, A. Rao, H. White)

    
    %% Non-UI properties
    properties
        % names of input variables, as selected by user in the UI
        InputNames cell
        
        % index of this test case
        Index double
        
        % Submission type this test case belongs to
        ParentType SubmissionType
        
        % Whether there is an error or not
        IsErrored logical = false
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
        % note: has to be a cell array for some reason
        InCommas cell %matlab.ui.control.Label
        
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
            % associate the object with the tab - used for verifying itself
            % in the SubmissionType's test case tab group selection changed
            % function
            this.Tab.UserData = this;
            this.ParentType = subType;
            this.Index = length(this.ParentType.TestCases) + 1;
            this.Tab.Title = sprintf('Test Case %d', this.Index);
            
            % populate with the function preview
            canvasSize = this.Tab.Position(3:4);
            
            % TODO: Have this take into account how many inputs/outputs and
            % try to center things
            % for now, just eyeballin it
            ypos = 0.5*canvasSize(end) - 22;
            
            % Create FunctionName
            this.FunctionName = uilabel(this.Tab);
            this.FunctionName.FontName = 'Courier New';
%             this.FunctionName.Position = [287 16 49 22];
            this.FunctionName.Position = [287 ypos 49 22];
            this.FunctionName.Text = '= %s(';
            
            
            % Create LeftOutBracket
            this.LeftOutBracket = uilabel(this.Tab);
            this.LeftOutBracket.FontName = 'Courier New';
            this.LeftOutBracket.Position = [235 ypos 10 22];
            this.LeftOutBracket.Text = '[';
            
            % Create RightInputParen
            this.RightInputParen = uilabel(this.Tab);
            this.RightInputParen.FontName = 'Courier New';
            this.RightInputParen.Position = [342 ypos 10 22];
            this.RightInputParen.Text = ')';
            
            % Create RightOutBracket
            this.RightOutBracket = uilabel(this.Tab);
            this.RightOutBracket.FontName = 'Courier New';
            this.RightOutBracket.Position = [263 ypos 10 22];
            this.RightOutBracket.Text = ']';
            
            redrawFunctionPreview(this);
            
            % TODO: look at slowdowns from this
            % big functions could take a long time if they are run 9 times
            % on app startup
            % this.verifySelf();
            
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
            this.Tab.Title = ['Test Case ', num2str(value)]; %#ok<*MCSUP>
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
            recenterLabels(this);
        end
        
    end
    
    methods (Access = public)
        
        function recenterLabels(this)
            rightmostPos = 0;
            % Finds the rightmost label, which will be either a comma or
            % the right paren
            for i = this.InCommas
                ic = i{1};
                if ic.Position(1) > rightmostPos
                    rightmostPos = ic.Position(1);
                end
            end
            if rightmostPos < this.RightInputParen.Position(1)
               rightmostPos = this.RightInputParen.Position(1); 
            end
            
            leftmostPos = this.LeftOutBracket.Position(1);
            totalPreviewWidth = rightmostPos - leftmostPos;
            % trying to center the whole thing in the middle of the tab
            halfwayPoint = leftmostPos + totalPreviewWidth / 2;
            canvasSize = this.Tab.Position(3:4);
            
            % account for the height of the tab label itself
            % CHANGE THIS IF THE TABS ARE CHANGED TO BE VERTICAL INSTEAD OF
            % HORIZONTAL
            canvasSize(2) = floor(canvasSize(2) - canvasSize(2) / 8);
            
            % this is the distance each component has to move individually
            % for the entire thing to be centered
            horizontalDistanceToMove = floor(canvasSize(1) / 2 - halfwayPoint);
            
            
            % Now it's time to do the same but for height!!
            % It's easier this time, because the highest thing is anything
            % on the first line and the lowest thing is always the last
            % output paren
            
            % position is [x y w h] where (x,y) is the bottom left corner
            % so top left corner is y+h
            topmostPos = this.LeftOutBracket.Position(2) + this.LeftOutBracket.Position(4);
            bottommostPos = this.RightInputParen.Position(2);
            totalPreviewHeight = topmostPos - bottommostPos;
            verticalHalfwayPoint = bottommostPos + totalPreviewHeight / 2;
            verticalDistanceToMove = floor(canvasSize(2) / 2 - verticalHalfwayPoint);
            
            % Move everything over
            components = this.Tab.Children;
            for ind = 1:length(components)
                % move everything horizontally
                components(ind).Position(1) = components(ind).Position(1) + horizontalDistanceToMove;
                % move everything vertically
                components(ind).Position(2) = components(ind).Position(2) + verticalDistanceToMove;

            end


        end
        
        function addOutputNameEditFields(this)
            value = this.ParentType.Problem.NumOutputs;
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
                vars = this.ParentType.OutputNames((value*(this.Index - 1) + 1):(this.Index*value));
                vars = ['[', strjoin(vars, ','), ']'];
                this.RightOutBracket.Visible = 'off';
                posn = this.LeftOutBracket.Position;
                this.LeftOutBracket.Position = [...
                    this.FunctionName.Position(1) - (this.CHAR_WIDTH * length(vars)), ...
                    posn(2), this.CHAR_WIDTH * length(vars), posn(4)];
                this.LeftOutBracket.Text = vars;
            else
                this.RightOutBracket.Position = [this.FunctionName.Position(1:2), this.CHAR_WIDTH, ...
                    this.FunctionName.Position(4)];
                this.LeftOutBracket.Position = this.RightOutBracket.Position - [this.CHAR_WIDTH 0 0 0];
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
            CUSTOM_WIDTH = 16;
            DEFAULT_TESTCASE_NUM = 3;
            % do separate things if auto or not
            % if auto, always out#
            % otherwise, length of each tb? -> 8 chars
            % create var names
            if ~isempty(this.InputDropdowns)
                delete(this.InputDropdowns);
            end
            
            if ~isempty(this.InCommas)
                %                 delete(this.InCommas);
                cellfun(@delete, this.InCommas);
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
                % see if any patterns
                vars = TestCase.getInputsFromWorkspace();
                numArgs = value * DEFAULT_TESTCASE_NUM;
                orders = detectPattern(vars, numArgs);
                % if nothing, then isAuto = false
                isAuto = ~isempty(orders);
                if isAuto
                    % create load
                    % likeliest candidate is one with same num vars. If
                    % multiple, then depends. look for type name (or abbr).
                    % If all else fails, pick first.
                    % if still more than one, look for type name or abbr.
                    if numel(orders) > 1
                        % see if any of them contain this
                        possibleChains = cellfun(@(c)(c{1}), orders, 'uni', false);
                        % we have representatives from all. See if contains
                        % any of the possible
                        % this gets... tricky. For resubmission, it contain
                        % any of the following:
                        %   resub, resubmission, re, alt, _b
                        % For submission, it contains any of the following:
                        %   sub, submission, _a
                        % For student, this is going to be the default, so
                        % it might not even HAVE anything useful. However,
                        % look for the following:
                        %   stud, student
                        %
                        % Here's where it gets tricky. Suppose we have the
                        % following order:
                        %   in1_submission, ...
                        %   in1_resubmission, ...
                        %
                        % obviously, in1_submission -> sub,
                        % in1_resubmission -> resub. However, sub is in
                        % resubmission, and so is submission! the word is
                        % contained within the word - theoretically,
                        % in1_resubmission could be in1_re + submission, or
                        % in1_ + resubmission
                        %
                        % to a human, this is obviously resubmission. So
                        % what's the rule behind it?
                        %
                        % So we have to care what we're looking at. If we
                        % are looking at the word "submission", we want to
                        % make sure it doesn't ALSO say "resubmission"
                        %
                        % If we are in resubmission, look for resub,
                        % resubmission, re, alt, _b.
                        if strcmp(this.ParentType.Name, 'Resubmission')
                            % look for:
                            %   resub
                            %
                            % We don't need to worry about containment here
                            % - resub won't be inside!
                            mask = contains(possibleChains, 'resub', 'IgnoreCase', true);
                        elseif strcmp(this.ParentType.Name, 'Submission')
                            % look for:
                            %   sub, orig.
                            %
                            % We DO need to worry about containment here.
                            % If we find submission, make sure we ALSO
                            % don't find resubmission!
                            mask = contains(possibleChains, {'sub', 'orig'}, 'IgnoreCase', true);
                            % for original and orig, who cares. For
                            % submission, make sure we don't find
                            % resubmission. Because sub is in submission,
                            % and resub is in resubmission, as long as we
                            % don't find resub, good to go.
                            mask = mask & ~contains(possibleChains, 'resub', 'IgnoreCase', true);
                        else
                            % look for:
                            %   stud, student
                            % don't' need to worry about containment!
                            mask = contains(possibleChains, 'stud', 'IgnoreCase', true);
                        end
                        if any(mask)
                            orders = orders(mask);
                        end
                        
                    % if we still have more, then only save any with
                    % exact same # of args
                    lens = cellfun(@length, orders);
                    [lens, inds] = sort(lens);
                    orders = orders(inds);
                    if any(lens == numArgs)
                        orders(lens ~= numArgs) = [];
                    end
                        
                        defaultArgs = orders{1};
                    else
                        defaultArgs = orders{1};
                    end
                    % we have figured out what default args are. Extract
                    % our own index
                    startInd = ((this.Index - 1) * value) + 1;
                    defaultArgs = defaultArgs(startInd:(startInd + value - 1));
                end
                % 
                for e = 1:value
                    if e ~= 1
                        % add comma
                        tmp = uilabel(this.Tab, 'FontName', 'Courier New', ...
                            'FontSize', 12, 'Text', ',');
                        tmp.Position = [...
                            sum(this.InputDropdowns(e - 1).Position([1 3])), posn(2), this.CHAR_WIDTH, posn(4)];
                        this.InCommas{e} = tmp;
                    end
                    
                    tmp = uidropdown(this.Tab, 'FontName', 'Courier New', ...
                        'FontSize', 12);
                    
                    %                     baseVars = evalin('base', 'who');
                    %                     tmp.Items = baseVars(~strcmp(baseVars, 'ans'));
                    baseVars = TestCase.getInputsFromWorkspace();
                    tmp.Items = baseVars;
                    if isempty(tmp.Items)
                        
                    elseif isAuto
                        tmp.Value = defaultArgs{e};
                        this.InputNames{e} = tmp.Value;
                    else
                        tmp.Value = tmp.Items{mod(e - 1, length(tmp.Items)) + 1};
                        this.InputNames{e} = tmp.Value;
                    end
                    
                    %                     tmp.ValueChangedFcn = createCallbackFcn(app, @(a, ev)(inputBaseWordEditFieldChanged(a, ev, subType, e)), true);
                    tmp.ValueChangedFcn = @(dropDown, ev)(this.updateInputsList(dropDown.Value, e));
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
            
            % Necessary because the first comma is placed into the second
            % position of the InCommas cell array
            if ~isempty(this.InCommas)
                this.InCommas = this.InCommas(2:end);
            end
        end
        
        %% autofillDropdowns Fills dropdowns with a cell array of items
        function autofillDropdowns(this, items)
            for ind = 1:length(this.InputDropdowns)
                dd = this.InputDropdowns(ind);
                item = items{ind};
                dd.Value = item;
            end
        end
        
        %% updateInputsList
        %
        % Called whenever one of the input dropdowns is changed.
        function updateInputsList(this, selectedName, ind)
            if ~isempty(selectedName)
                this.InputNames{ind} = selectedName;
            end
        end
        
        %% updateAllDropdowns
        %
        % Updates all dropdowns with the new variable list.
        function updateAllDropdowns(this)
            newInputs = TestCase.getInputsFromWorkspace();
            supFiles = this.ParentType.SupportingFilesListBox.Items;
            newInputs = [newInputs', compose('''%s''', string(supFiles))];
            for dd = 1:length(this.InputDropdowns)
                this.InputDropdowns(dd).Items = newInputs;
                this.updateInputsList(this.InputDropdowns(dd).Value, dd);
            end
            this.verifySelf();
        end
        
        %% verifySelf
        %
        % Verifies this single test case. Essentially a stripped-down
        % version of the full verify() function, used to test a single
        % function call only.
        function result = verifySelf(this)
            result = true;
            tempdir = tempname();
            mkdir(tempdir);
            orig = cd(tempdir);
            cleanup = onCleanup(@()(cleaner(orig, tempdir)));
            % create web
            fid = fopen('./web.m', 'wt');
            fprintf(fid, 'function varargout = web(varargin)\n\tvarargout=cell(1, nargout);\nend');
            fclose(fid);
            % copy supporting files to temp directory
            for ind = 1:length(this.ParentType.SupportingFiles)
                fi = this.ParentType.SupportingFiles{ind};
                copyfile(fi);
            end
            
            % copy soln
            copyfile(this.ParentType.Problem.FunctionPath);
            fnName = this.ParentType.Problem.FunctionName;
            
            % build the function call
            if ~isempty(this.InputNames)
                call = sprintf('%s(%s);', fnName, strjoin(this.InputNames, ',')); %#ok<NASGU>
                f = figure('Visible', 'off');
                try
                    evalc('evalin(''base'', call);');

                    % if it worked, then great
    %                 this.Tab.Title = strrep(this.Tab.Title, TestCaseCompiler_Layout.ERROR_ICON, '');
                    this.IsErrored = false;
                catch
                    % failed, so fuck you
                    % TODO: set dropdowns red maybe?
    %                 currentTitle = this.Tab.Title;
    %                 if ~contains(currentTitle, TestCaseCompiler_Layout.ERROR_ICON)
    %                     this.Tab.Title = [TestCaseCompiler_Layout.ERROR_ICON, currentTitle];
    %                 end
                    this.IsErrored = true;
                    result = false;
                end
                close(f);
            else
                result = false;
            end
            
            function cleaner(orig, temp)
                cd(orig);
                rmdir(temp, 's');
            end
            
            
        end
        

    end
    
    methods
        %% IsErrored Whether this test case has an error
        function set.IsErrored(this, value)
            if value
                if ~contains(this.Tab.Title, TestCaseCompiler_Layout.ERROR_ICON) %#ok<*MCSUP>
                    this.Tab.Title = [TestCaseCompiler_Layout.ERROR_ICON, this.Tab.Title];
                end
            else
                this.Tab.Title = strrep(this.Tab.Title, TestCaseCompiler_Layout.ERROR_ICON, '');
            end
        end
    end
    
    %% Utility methods
    methods (Static)
        %% getInputsFromWorkspace
        %
        % Gets all variables from the command window workspace (except ans).
        function baseVars = getInputsFromWorkspace()
            baseVars = evalin('base', 'who');
            baseVars = baseVars(~strcmp(baseVars, 'ans'));
%             dropDown.Items = baseVars(~strcmp(baseVars, 'ans'));
        end
        
        %% createFromPackage Creates a test case from a loaded package
        function tc = createFromPackage(tabGroup, parentType, infoSt)
            persistent resolution;
            if isempty(resolution)
                resolution = struct();
            end
            % load variables into workspace
            % TODO: check for conflicts here
            % check load file
            vars = load(infoSt.loadFile);
            % see if we even have any conflicts
            main = evalin('base', 'who');
            archive = fieldnames(vars);
            mask = ismember(archive, main);
            % mask is true where archive variable name matches a main
            % variable name
            possible = archive(mask);
            isClean = true(size(possible));
            for p = numel(possible):-1:1
                % IF we already have a resolution, then the conflict has
                % already been resolved - just replace the value with out
                % own
                if isfield(resolution, possible{p})
                    isClean(p) = true;
                    vars.(possible{p}) = resolution.(possible{p});
                else
                    isClean(p) = isequaln(evalin('base', possible{p}), ...
                        vars.(possible{p}));
                end
            end
            mask(mask) = ~isClean;
            % now, mask is true where we have a death
            % if we have conflict, manage
            % check our conflict resolution variable. If we find it, just
            % use that value instead.
            
            if any(mask)
                vals = struct2cell(vars);
                conflicts = archive(mask);
                vals = vals(mask);
                conflictSt = cell2struct(vals, conflicts);
                conflictManager = Conflicts(conflictSt);
                uiwait(conflictManager.UIFigure);
                if ~isvalid(conflictManager) || ~isvalid(conflictManager.UIFigure)
                    throw(MException('TESTCASE:createFromPackage:conflicts', ...
                        'No conflict resolution given'));
                end
                % for each one that WAS main, replace our own with main
                toReplace = conflicts(conflictManager.IsMain);
                for t = 1:numel(toReplace)
                    vars.(toReplace{t}) = evalin('base', toReplace{t});
                end
                close(conflictManager.UIFigure);
            end
            % guaranteed to be clean, but we save in ever growing
            % resolution, for future reference.
            for v = 1:numel(archive)
                resolution.(archive{v}) = vars.(archive{v});
                assignin('base', archive{v}, vars.(archive{v}));
            end
            tc = TestCase(tabGroup, parentType);
            value = parentType.Problem.NumInputs;
            tcInputs = infoSt.ins((value*(tc.Index - 1) + 1):(tc.Index*value));
            tc.InputNames = tcInputs;
            tc.autofillDropdowns(tcInputs);
            tc.verifySelf();
        end
    end
end

