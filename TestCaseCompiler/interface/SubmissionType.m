classdef SubmissionType < handle
    %% SubmissionType Represent a category of submission
    %
    % This class represents a category of submission, such as 'student',
    % 'submission', or 'resubmission'. A SubmissionType object stores data
    % particular to each submission category, including the test cases
    % themselves, supporting files, and base words.
    %
    % % (c) 2018 CS1371 (J. Htay, D. Profili, A. Rao, H. White)
    
    %% Non-UI properties %%
    properties
        % Cell array of output base words
        OutputBaseWords cell
        
        % Array of test cases
        TestCases TestCase
        
        % Cell array of full paths to supporting files
        SupportingFiles cell
        
        % Parent problem
        Problem Problem
    end
    
    properties (SetAccess = immutable)
        % The name of the submission type/category
        Name char
    end
    
    properties
        % The number of test cases this submission type has (3 by default)
        NumTestCases
        
        % Cell array of the actual output names
        OutputNames cell
        
        % all input values for this submission type
        InputValues cell
        
        % all input names for this submission type
        InputNames cell
    end
    
    %% UI properties %%
    properties
        AddTestCaseButton matlab.ui.control.Button
        RemoveTestCaseButton matlab.ui.control.Button
        Tab matlab.ui.container.Tab
        
        % supporting files elements
        SupportingFilesAddButton matlab.ui.control.Button
        SupportingFilesRemoveButton matlab.ui.control.Button
        SupportingFilesPanel matlab.ui.container.Panel
        SupportingFilesListBox matlab.ui.control.ListBox
        
        % output base words elements
        OutputBaseWordsPanel matlab.ui.container.Panel
        OutputBaseWordsEditField matlab.ui.control.EditField
        
        % tab group containing the test cases
        TabGroup matlab.ui.container.TabGroup
        
    end
    
    properties (Access = private)
        
        % currently focused test case
        focusedTestCaseNum = 1
    end
    
    properties (Constant, Access = public)
        MIN_NUM_TEST_CASES = 3
        
        % color for editfields (i.e. the output base edit field)
        % for when there is an error
        EDITFIELD_ERROR_COLOR = [1.0, 0, 0]
        
    end
    
    methods
        %% Constructor
        %
        % obj = SubmissionType(NAME) Constructs a new SubmissionType object with
        % name NAME and everything else uninitialized, if NAME is among the
        % allowed submission type names. If it is not, a
        % TESTCASE:SubmissionType:ctor:invalidSubmissionType exception is
        % thrown.
        function this = SubmissionType(name, parent, parentTabGroup)
            this.Name = name;
            this.Problem = parent;
            %             this.tabGroup = testCaseTabGroup;
            %             delete(parentTabGroup.Children);
            
            % default base word is 'out'
            defaultWord = 'out';
            if this.Problem.NumOutputs <= 1
                this.OutputBaseWords = {defaultWord};
            else
                this.OutputBaseWords = cell(1, this.Problem.NumOutputs);
                for i = 1:this.Problem.NumOutputs
                    % FIX: this assumes that there won't be any problems
                    % with more than 26 outputs. I think that's a
                    % reasonable assumption so for the sake of sanity I'm
                    % not going to account for an arbitrary number of
                    % outputs. If anyone has to fix this then you can go fuck
                    % yourself.
                    this.OutputBaseWords{i} = [defaultWord, char('A' + i - 1)];
                end
            end


            this.createSubmissionTab(parentTabGroup, parent.Layout);

            % create the default number of test case tabs
            for i = 1:this.MIN_NUM_TEST_CASES
                %                 this.addTestCase();
                this.TestCases(end + 1) = TestCase(this.TabGroup, this);

            end
            this.NumTestCases = this.MIN_NUM_TEST_CASES;
        end
        
        %% loadFromPackage
        %
        % Loads a submission tab data from a package.
        %
        function loadFromPackage(this, infoSt, parentTabGroup)
            % supporting files list is relative paths, so add the folder
%             this.SupportingFiles = infoSt.supportingFiles;
            if ~isempty(infoSt.supportingFiles)
                this.SupportingFiles = cellfun(@(x)(fullfile(pwd, 'supportingFiles', ...
                    x)), infoSt.supportingFiles, 'UniformOutput', false);
            end
            
            if ~iscell(infoSt.supportingFiles)
                supFilesNames = {};
            else
                supFilesNames = infoSt.supportingFiles;
            end
            this.NumTestCases = length(infoSt.calls);
            this.OutputBaseWords = infoSt.outBase;
            this.OutputNames = infoSt.outs;
            
            % get the layout
            layout = this.Problem.Layout;
            
            % create autofilled tab
            this.createTab(parentTabGroup);
            this.createSupportingFilesPanel(layout, this.SupportingFiles);
            this.createOutputBaseWordsPanel(layout, strjoin(this.OutputBaseWords, ', '));
            % note - just drawing the filenames only. the full paths to
            % supporting files are saved internally
            this.createSupportingFilesPanel(layout, supFilesNames);
            this.createSubmissionValuesTabGroup(layout);
            this.createTestCaseAddRemoveButtons(layout);
            
            % create the test cases
            this.TestCases = TestCase.empty();
            for i = 1:this.NumTestCases
               this.TestCases(end + 1) = TestCase.createFromPackage(this.TabGroup, this, infoSt); 
            end
        end
        
        %% createSubmissionTab
        %
        % Populates a tab with all the UI elements common to submission
        % type tabs (i.e. test case tab group, supporting files, output
        % words, and add/remove buttons).
        %
        % Everything is created blank.
        function createSubmissionTab(this, parentTabGroup, layout)
            % Create the tab
            this.createTab(parentTabGroup);
            
            % Create SupportingFilesPanel
            this.createSupportingFilesPanel(layout, {});
                                    
            % Create OutputBaseWordsPanel
            this.createOutputBaseWordsPanel(layout, '');
            
            % Create SubmissionValuesTabGroup
            this.createSubmissionValuesTabGroup(layout);
            
            % buttons
            this.createTestCaseAddRemoveButtons(layout);
        end
        
        %% createTab Creates the tab object
        function createTab(this, parentTabGroup)
            this.Tab = uitab(parentTabGroup, 'title', this.Name);
            this.Tab.UserData = this;
        end
        
        %% createSupportingFilesPanel Creates the supporting files panel object
        function createSupportingFilesPanel(this, layout, items)
            % panel itself
            this.SupportingFilesPanel = uipanel(this.Tab);
            this.SupportingFilesPanel.Title = 'Supporting Files';
%             this.SupportingFilesPanel.Position = [11 132 370 94];
            this.SupportingFilesPanel.Position = layout.SupportingFilesPanel;
            
            % remove button
            this.SupportingFilesRemoveButton = uibutton(this.SupportingFilesPanel, 'push');
            this.SupportingFilesRemoveButton.BackgroundColor = [0.902 0.902 0.902];
%             this.SupportingFilesRemoveButton.Position = [261 12 100 22];
            this.SupportingFilesRemoveButton.Position = layout.SupportingFilesRemoveButton;
            this.SupportingFilesRemoveButton.Text = 'Remove';
            this.SupportingFilesRemoveButton.ButtonPushedFcn = @(a, ev)(this.removeSupportingFiles());
            
            % add button
            this.SupportingFilesAddButton = uibutton(this.SupportingFilesPanel, 'push');
            this.SupportingFilesAddButton.BackgroundColor = [0.902 0.902 0.902];
%             this.SupportingFilesAddButton.Position = [261 42 100 22];
            this.SupportingFilesAddButton.Position = layout.SupportingFilesAddButton;
            this.SupportingFilesAddButton.Text = 'Add...';
            this.SupportingFilesAddButton.ButtonPushedFcn = @(a, ev)(this.addSupportingFiles());
            
            % create the list box
            this.createSupportingFilesListBox(items, layout);

        end
        
        %% createSupportingFilesListBox Creates the list box for supporting files
        function createSupportingFilesListBox(this, items, layout)
            this.SupportingFilesListBox = uilistbox(this.SupportingFilesPanel);
            this.SupportingFilesListBox.Items = items;
            this.SupportingFilesListBox.FontName = 'Consolas';
%             this.SupportingFilesListBox.Position = [10 14 241 50];
            this.SupportingFilesListBox.Position = layout.SupportingFilesListBox;
            this.SupportingFilesListBox.Value = {};
        end
        
        %% createOutputBaseWordsPanel Creates the output base words panel and editfield
        function createOutputBaseWordsPanel(this, layout, txt)
            this.OutputBaseWordsPanel = uipanel(this.Tab);
            this.OutputBaseWordsPanel.Title = 'Output Base Words';
%             this.OutputBaseWordsPanel.Position = [391 132 280 94];
            this.OutputBaseWordsPanel.Position = layout.OutputBaseWordsPanel;
            
            % Create OutputBaseWordsEditField
            this.OutputBaseWordsEditField = uieditfield(this.OutputBaseWordsPanel, 'text');
            this.OutputBaseWordsEditField.FontName = 'Consolas';
%             this.OutputBaseWordsEditField.Position = [21 28 238 22];
            this.OutputBaseWordsEditField.Position = layout.OutputBaseWordsEditField;
            this.OutputBaseWordsEditField.ValueChangedFcn = @(a, ev)(this.changeBaseWords(ev.Source));
            this.OutputBaseWordsEditField.Value = txt;
            if this.Problem.NumOutputs == 0
                this.OutputBaseWordsEditField.Enable = 'off';
            end
        end
        
        %% createSubmissionValuesTabGroup Creates the submission values tab group
        function createSubmissionValuesTabGroup(this, layout)
            this.TabGroup = uitabgroup(this.Tab);
%             this.TabGroup.Position = [11 46 660 77];
            this.TabGroup.Position = layout.ValuesTabGroup;
            this.TabGroup.SelectionChangedFcn = @(a, ev)(this.setFocusedTestCase(ev.Source));
        end
        
        %% createTestCaseAddRemoveButtons Creates the add/remove buttons for test cases
        function createTestCaseAddRemoveButtons(this, layout)
            % Create RemoveTestCaseButton
            this.RemoveTestCaseButton = uibutton(this.Tab, 'push');
            %             this.RemoveTestCaseButton.ButtonPushedFcn = createCallbackFcn(this, @StudentRemoveTestCaseButtonPushed, true);
            this.RemoveTestCaseButton.FontName = 'Courier New';
            this.RemoveTestCaseButton.Enable = 'off';
%             this.RemoveTestCaseButton.Position = [51 13 31 22];
            this.RemoveTestCaseButton.Position = layout.RemoveTestCaseButton;
            this.RemoveTestCaseButton.Text = '-';
            this.RemoveTestCaseButton.Enable = 'off';
            this.RemoveTestCaseButton.ButtonPushedFcn = @(a, ev)(this.deleteTestCase());
            
            % Create AddTestCaseButton
            this.AddTestCaseButton = uibutton(this.Tab, 'push');
            %             this.AddTestCaseButton.ButtonPushedFcn = createCallbackFcn(this, @StudentAddTestCaseButtonPushed, true);
            this.AddTestCaseButton.FontName = 'Courier New';
%             this.AddTestCaseButton.Position = [11 13 31 22];
            this.AddTestCaseButton.Position = layout.AddTestCaseButton;
            this.AddTestCaseButton.Text = '+';
            this.AddTestCaseButton.ButtonPushedFcn = @(a, ev)(this.addTestCase());
        end
        
        %% deleteTestCase Deletes a test case
        %
        % Removes the corresponding tab from the UI and reorganizes the
        % other tabs accordingly.
        function deleteTestCase(this)
            num = this.focusedTestCaseNum;
            this.TestCases(num).deleteTestCase();
            this.NumTestCases = this.NumTestCases - 1;
            this.TestCases(num) = [];
            
            % relabel other test case tabs
            for i = 1:this.NumTestCases
                this.TestCases(i).Index = i;
                this.TestCases(i).addOutputNameEditFields();
                
            end
            
            % disable remove button if <= minimum # test cases
            if this.NumTestCases <= this.MIN_NUM_TEST_CASES
                this.RemoveTestCaseButton.Enable = 'off';
            end
        end
        
        %% addTestCase Adds a test case
        %
        % Adds the corresponding tab to the end of the list.
        function addTestCase(this)
            this.NumTestCases = this.NumTestCases + 1;
            this.TestCases(end + 1) = TestCase(this.TabGroup, this);
            if length(this.TestCases) > this.MIN_NUM_TEST_CASES
                this.RemoveTestCaseButton.Enable = 'on';
            end
        end
        
        function value = get.OutputNames(this)
            if length(this.TestCases) < this.MIN_NUM_TEST_CASES
                len = this.MIN_NUM_TEST_CASES;
            else
                len = this.NumTestCases;
            end
            %             len = this.NumTestCases;
            value = generateVarNames(this.OutputBaseWords, this.Problem.NumOutputs, ...
                len);
        end
        
        %% setFocusedTestCase
        %
        % Sets the currently focused test case. Used to remove the current
        % test case.
        %
        % Also verifies the function call on the current test case.
        function setFocusedTestCase(this, tabGroup)
            name = tabGroup.SelectedTab.Title;
            num = str2double(name(name >= '0' & name <= '9'));
            
            % verify the single test case
            tc = this.TestCases(this.focusedTestCaseNum).Tab.UserData;
            tc.verifySelf();
            
            % set the number of the new focused test case
            this.focusedTestCaseNum = num;
        end
        
        %% verifyAllTestCases
        %
        % Verifies all test cases for this submission type. Returns true if
        % all test cases pass and false if any of them fail.
        function result = verifyAllTestCases(this)
            result = true;
            for tc = this.TestCases
                out = tc.verifySelf();
                result = result && out;
            end
        end
        
        %% changeBaseWords
        %
        % Callback for when the base words edit field is changed.
        function changeBaseWords(this, editField)
            value = editField.Value;
            % split input by commas
            baseWords = strsplit(value, ', ');
            if length(baseWords) ~= this.Problem.NumOutputs
                editField.BackgroundColor = this.EDITFIELD_ERROR_COLOR;
                uiconfirm(SubmissionType.getParentFigure(editField), sprintf('You entered %d outputs, but %s has only %d outputs.', ...
                    length(baseWords), this.Problem.FunctionName, this.Problem.NumOutputs), ...
                    'Error', 'Icon', 'error');
            else
                editField.BackgroundColor = [1, 1, 1];
                this.OutputBaseWords = cellfun(@strtrim, baseWords, 'UniformOutput', false);
                for i = 1:this.NumTestCases
                    this.TestCases(i).addOutputNameEditFields();
                end
            end
        end
        
        %% addSupportingFiles Adds supporting files
        %
        % Called when the user clicks the "add" button in the supporting files window.
        %
        %   subType - 'Student', 'Submission', or 'Resubmission'
        function addSupportingFiles(this)
            listBox = this.SupportingFilesListBox;
            [filename, path] = uigetfile('*', 'Select supporting files', 'MultiSelect', 'on');
            SubmissionType.makeVisible(SubmissionType.getParentFigure(listBox));
            fullpath = fullfile(path, filename);
            if ~iscell(fullpath)
                fullpath = {fullpath};
            end
            if ~iscell(filename)
                filename = {filename};
            end
            if (ischar(filename) && ischar(path)) || (iscell(filename) && ischar(path))
                if any(strcmp(fullpath, this.Problem.FunctionPath))
                    uiconfirm(SubmissionType.getParentFigure(listBox), 'You can''t add the solution function as a supporting file!', ...
                        'Error', 'Icon', 'error');
                    % delete the function file from the list of selected files
                    mask = strcmp(fullpath, this.Problem.FunctionPath);
                    fullpath(mask) = [];
                    filename(mask) = [];
                end
                
                % remove duplicates, if any
                for i = length(fullpath):-1:1
                    if any(strcmp(fullpath{i}, this.SupportingFiles))
                        % sassily focus on that one in the listbox
                        listBox.Value = listBox.Items(strcmp(fullpath{i}, this.SupportingFiles));
                        % delete it from the list of files to add
                        fullpath(i) = [];
                        filename(i) = [];
                    end
                end
                % if user actually picked something and didn't cancel, add to the list
                items = listBox.Items;
                items = [items, filename];
                listBox.Items = items;
                this.SupportingFiles = [this.SupportingFiles, fullpath];
                
            else
                
            end
            
            
        end
        
        %% removeSupportingFiles
        %
        % Callback for when the 'remove' button is pressed for the
        % supporting files.
        function removeSupportingFiles(this)
            listBox = this.SupportingFilesListBox;
            selected = listBox.Value;
            if ~isempty(selected)
                items = listBox.Items;
                loc = strcmp(items, selected);
                items = items(~loc);
                listBox.Items = items;
                this.SupportingFiles = this.SupportingFiles(~loc);
            end
            
        end
        
        %% InputNames
        %
        % Agglomerates all input names from all test cases into one cell
        % array. But not really though. Actually, it puts inputs into cell
        % arrays, which are then put into a 1x(numTestCases) cell array.
        function value = get.InputNames(this)
            value = cell(1, numel(this.TestCases));
            for t = 1:numel(this.TestCases)
                tc = this.TestCases(t);
                value{t} = [tc.InputNames{:}];
            end
            value = [value{:}];
            
        end
        
        function value = get.InputValues(this)
            names = this.InputNames;
            value = cell(1, length(names));
            for i = 1:length(names)
                try
%                     for j = 1:length(names{i})
%                         temp{j} = evalin('base', names{i}{j});
%                     end
%                     value{i} = temp;
                    value{i} = evalin('base', names{i});
                catch ME
                    % something didn't work
                    % variable missing?
                    error('kill me plz');
                end
            end
            
        end
            
        
        %% refreshInputsList
        %
        % Refreshes the inputs list by re-importing variable names from the
        % workspace.
        function refreshInputsList(this)
            for tc = this.TestCases
                tc.updateAllDropdowns();
            end
        end
    end
    
    %% Utility methods
    methods (Static)
        %% getParentFigure
        %
        % Gets the parent UIfigure object of a child element.
        function p = getParentFigure(elem)
            try
                if isa(elem, 'matlab.ui.Figure') || ~isprop(elem, 'Parent')
                    p = elem;
                else
                    p = SubmissionType.getParentFigure(elem.Parent);
                end
            catch
                % TODO: do this better
                p = [];
            end
            
        end
        
        %% makeVisible Forces the app window to become visible
        %
        % A workaround for the annoying habit of uigetfile() to minimize the uifigure it is
        % called from.
        %
        function makeVisible(fig)
            fig.Visible = 'off';
            fig.Visible = 'on';
        end
        
        
    end
end

