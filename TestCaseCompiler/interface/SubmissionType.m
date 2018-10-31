classdef SubmissionType < handle
    %% SubmissionType Represent a category of submission
    %
    % This class represents a category of submission, such as 'student',
    % 'submission', or 'resubmission'. A SubmissionType object stores data
    % particular to each submission category, including the test cases
    % themselves, supporting files, and base words.
    %
    % @authors Justin Htay, Daniel Profili, Hannah White
    
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
    
    properties (SetAccess = private)
        % The number of test cases this submission type has (3 by default)
        NumTestCases
        
        % Cell array of the actual output names
        OutputNames cell
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
        focusedTestCaseNum double
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
            this.OutputBaseWords = {'out'};

            
            createSubmissionTab(this, parentTabGroup);
            
            % create the default number of test case tabs
            for i = 1:this.MIN_NUM_TEST_CASES
%                 this.addTestCase();
                this.TestCases(end + 1) = TestCase(this.TabGroup, this);
                
            end
            this.NumTestCases = this.MIN_NUM_TEST_CASES;
            
        end
        
        %% createSubmissionTab
        %
        % Populates a tab with all the UI elements common to submission
        % type tabs (i.e. test case tab group, supporting files, output
        % words, and add/remove buttons).
        function createSubmissionTab(this, parentTabGroup)
            this.Tab = uitab(parentTabGroup, 'title', this.Name);
            
            % Create SupportingFilesPanel
            this.SupportingFilesPanel = uipanel(this.Tab);
            this.SupportingFilesPanel.Title = 'Supporting Files';
            this.SupportingFilesPanel.Position = [11 132 370 94];

            % Create SupportingFilesAddButton
            this.SupportingFilesAddButton = uibutton(this.SupportingFilesPanel, 'push');
            this.SupportingFilesAddButton.BackgroundColor = [0.902 0.902 0.902];
            this.SupportingFilesAddButton.Position = [261 42 100 22];
            this.SupportingFilesAddButton.Text = 'Add...';

            % Create SupportingFilesRemoveButton
            this.SupportingFilesRemoveButton = uibutton(this.SupportingFilesPanel, 'push');
            this.SupportingFilesRemoveButton.BackgroundColor = [0.902 0.902 0.902];
            this.SupportingFilesRemoveButton.Position = [261 12 100 22];
            this.SupportingFilesRemoveButton.Text = 'Remove';

            % Create SupportingFilesListBox
            this.SupportingFilesListBox = uilistbox(this.SupportingFilesPanel);
            this.SupportingFilesListBox.Items = {};
            this.SupportingFilesListBox.FontName = 'Consolas';
            this.SupportingFilesListBox.Position = [10 14 241 50];
            this.SupportingFilesListBox.Value = {};
            
            % Create OutputBaseWordsPanel
            this.OutputBaseWordsPanel = uipanel(this.Tab);
            this.OutputBaseWordsPanel.Title = 'Output Base Words';
            this.OutputBaseWordsPanel.Position = [391 132 280 94];

            % Create OutputBaseWordsEditField
            this.OutputBaseWordsEditField = uieditfield(this.OutputBaseWordsPanel, 'text');
            this.OutputBaseWordsEditField.FontName = 'Consolas';
            this.OutputBaseWordsEditField.Position = [21 28 238 22];
            this.OutputBaseWordsEditField.ValueChangedFcn = @(a, ev)(this.changeBaseWords(ev.Source));

            % Create SubmissionValuesTabGroup
            this.TabGroup = uitabgroup(this.Tab);
            this.TabGroup.Position = [11 46 660 77];
            this.TabGroup.SelectionChangedFcn = @(a, ev)(this.setFocusedTestCase(ev.Source));
            
            % Create RemoveTestCaseButton
            this.RemoveTestCaseButton = uibutton(this.Tab, 'push');
%             this.RemoveTestCaseButton.ButtonPushedFcn = createCallbackFcn(this, @StudentRemoveTestCaseButtonPushed, true);
            this.RemoveTestCaseButton.FontName = 'Courier New';
            this.RemoveTestCaseButton.Enable = 'off';
            this.RemoveTestCaseButton.Position = [51 13 31 22];
            this.RemoveTestCaseButton.Text = '-';
            this.RemoveTestCaseButton.Enable = false;
            this.RemoveTestCaseButton.ButtonPushedFcn = @(a, ev)(this.deleteTestCase());

            % Create AddTestCaseButton
            this.AddTestCaseButton = uibutton(this.Tab, 'push');
%             this.AddTestCaseButton.ButtonPushedFcn = createCallbackFcn(this, @StudentAddTestCaseButtonPushed, true);
            this.AddTestCaseButton.FontName = 'Courier New';
            this.AddTestCaseButton.Position = [11 13 31 22];
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
                this.RemoveTestCaseButton.Enable = false;
            end
        end
        
        %% addTestCase Adds a test case
        %
        % Adds the corresponding tab to the end of the list.
        function addTestCase(this)
            this.NumTestCases = this.NumTestCases + 1;
            this.TestCases(end + 1) = TestCase(this.TabGroup, this);
            if length(this.TestCases) > this.MIN_NUM_TEST_CASES
                this.RemoveTestCaseButton.Enable = true;
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
        function setFocusedTestCase(this, tabGroup)
           	name = tabGroup.SelectedTab.Title;
            num = str2num(name(name >= '0' & name <= '9'));
            this.focusedTestCaseNum = num;
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
    end
    
    %% Utility methods
    methods (Static)
        %% getParentFigure
        %
        % Gets the parent UIfigure object of a child element.
        function p = getParentFigure(elem)
            try
                if isa(elem, 'matlab.ui.Figure')
                    p = elem;
                else
                    p = SubmissionType.getParentFigure(elem.Parent);
                end
            catch ME
                % TODO: do this better
                p = [];
            end
            
        end
        
        
    end
end

