classdef TestCaseCompiler < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        Menu                           matlab.ui.container.Menu
        QuitMenu                       matlab.ui.container.Menu
        HelpMenu                       matlab.ui.container.Menu
        HelpMenu_2                     matlab.ui.container.Menu
        AboutMenu                      matlab.ui.container.Menu
        RubricTabGroup                 matlab.ui.container.TabGroup
        StudentTab                     matlab.ui.container.Tab
        StudentSupportingFilesPanel    matlab.ui.container.Panel
        StudentSupportingFilesAddButton  matlab.ui.control.Button
        StudentSupportingFilesRemoveButton  matlab.ui.control.Button
        StudentSupportingFilesListBox  matlab.ui.control.ListBox
        StudentValuesTabGroup          matlab.ui.container.TabGroup
        StudentTestCase1Tab            matlab.ui.container.Tab
        StudentOutputBaseWordsPanel    matlab.ui.container.Panel
        StudentOutputBaseWordsEditField  matlab.ui.control.EditField
        StudentRemoveTestCaseButton    matlab.ui.control.Button
        StudentAddTestCaseButton       matlab.ui.control.Button
        CompileButton                  matlab.ui.control.Button
        ProblemSettingsPanel           matlab.ui.container.Panel
        RecursiveCheckBox              matlab.ui.control.CheckBox
        BannedFunctionsLabel           matlab.ui.control.Label
        BannedFunctionsListBox         matlab.ui.control.ListBox
        BannedFunctionsAddButton       matlab.ui.control.Button
        BannedFunctionsRemoveButton    matlab.ui.control.Button
        BannedFunctionsEditField       matlab.ui.control.EditField
        GeneralPanel                   matlab.ui.container.Panel
        FunctionLabel                  matlab.ui.control.Label
        FunctionBrowseButton           matlab.ui.control.Button
        SavetoLabel                    matlab.ui.control.Label
        OutputFolderBrowseButton       matlab.ui.control.Button
        FunctionNameField              matlab.ui.control.EditField
        LocalDiskCheckBox              matlab.ui.control.CheckBox
        GoogleDriveCheckBox            matlab.ui.control.CheckBox
        LocalBrowseButton              matlab.ui.control.Button
    end

    
    properties (Access = public, Constant)
        ERROR_SYMBOL = '? ' % Global error symbol, used to illustrate test case verification failure
    end
    
    properties (Hidden)
        % Auth stuff
        % used by the google drive browser when GoogleDriveBrowser() is called.
        token
        key = 'AIzaSyDrJfq4PT-johRn7Ws2xHdYR22yEcYJHOk'
        folderId
        exportDriveSelected = true
        exportLocalSelected = false        
        
        % user-selected path to local output
        LocalOutputDir char
        
        % directory for cleanup
        cleanupDir = cd()
        
        % structure of positions for all the components, by name
        Layout struct

    end
    
    properties (Access = protected)
        % problem object. holds everything.
        problem Problem
        
                
    end
    
    methods (Access = protected)
        
        %% loadFunction Load a solution function
        %
        % Does all the stuff that happens upon successful loading of a function solution file, including enabling
        % the disabled fields and setting some of the global problem params
        %
        %   path: full path to the solution file
        %   subType: 'Student', 'Submission', or 'Resubmission' only
        function loadFunction(app, path)
            makeVisible(app);
            % open a progress bar
            messages = {'Still faster than homework grading in CS1331', ...
                'DMS will be retired by the time this finishes', ...
                'Test team best team? More like test team pest team', ...
                '#daddiAddi', ...
                'Brought to you by your favorite TA''s favorite TA', ...
                'Please search before posting', ...
                'HOMEWORKTEAMTEAMWORKMAKESTHEHOMEWORKTEAMDREAMWORK', ...
                '~ An instructor (Justin Htay) thinks this beats the last one ~', ...
                'Clean the dang TA office', ...
                'imagePoker(''singleBlackPixel.png'')',...
                'Test team sucks at ultimate',...
                'Test team sucks at everything else',...
                };
            
                % show the progress bar using the wrapper class (to work with 2018a requirements)
            progBar = ProgressBar(app.UIFigure, 'Title', messages{randi([1 length(messages)])}, 'Message', sprintf('Loading %s...', ...
                'function'), 'Indeterminate', 'on');
            
            origDir = cd(fileparts(path));
            try
                delete(app.RubricTabGroup.Children);
                if app.ispackage(cd())
                    % load the package
                    app.problem = Problem(path, app.RubricTabGroup, app.Layout);
                    app.problem.loadFromPackage(cd, app.RubricTabGroup, app);
                else
                    % create a new problem
                    app.problem = Problem(path, app.RubricTabGroup, app.Layout);
                end
            catch ME
                cd(origDir);
                % if for some reason the function is invalid (selected a script, invalid path, etc)
                % then disable all the global problem settings fields and present an error message
                uiconfirm(app.UIFigure, ...
                    sprintf('Error: %s\n%s line %d', ME.message, ME.stack(1).file, ME.stack(1).line), ...
                    'Function load error', 'Options', {'OK'}, 'Icon', 'error');
                
                % make the edit field red
                app.FunctionNameField.BackgroundColor = [1.0 0 0];
                
                % compile button
                app.CompileButton.Enable = 'off';
%                 app.RefreshVariablesButton.Enable = 'on';
                return;
            end
            
            progBar.Value = 0.25;
            progBar.Message = 'Contacting MATLAB support...';
            progBar.Title = messages{randi([1 length(messages)])};
            
            
            % enable all the disabled fields
%             [~, fnName] = fileparts(path);
            app.FunctionNameField.Value = app.problem.FunctionName;
            app.FunctionNameField.FontName = 'Consolas';
            app.FunctionNameField.BackgroundColor = [1 1 1];
                        
            % compile button
            app.CompileButton.Enable = 'on';
%             app.RefreshVariablesButton.Enable = 'on';
            
            % problem settings panel
            app.enableAllChildren(app.ProblemSettingsPanel);
                        
            progBar.close();
        end
        
        %% makeVisible Forces the app window to become visible
        %
        % A workaround for the annoying habit of uigetfile() to minimize the uifigure it is
        % called from.
        %
        function makeVisible(app)
            app.UIFigure.Visible = 'off';
            app.UIFigure.Visible = 'on';
        end
        
        
        %% enableAllChildren Enables all child components of a component
        %
        % Used to quickly enable all components in a panel, tab group, etc.
        %
        function enableAllChildren(app, parent)
            if isprop(parent, 'Enable')
                parent.Enable = 'on';
            end
            
            if isprop(parent, 'Children')
                children = allchild(parent);
                for i = 1:length(children)
                    enableAllChildren(app, children(i));
                end
            end
        end
        
        %% disableAllChildren Disables all child components of a component
        %
        % Used to quickly disable all components in a panel, tab group, etc.
        %
        function disableAllChildren(app, parent)
            if isprop(parent, 'Enable')
                parent.Enable = 'off';
            end
            
            if isprop(parent, 'Children')
                children = allchild(parent);
                for i = 1:length(children)
                    disableAllChildren(app, children(i));
                end
                
            end
        end
        
        %% windowFocusGainedCallback Callback for when the window gains focus.
        % 
        % Used to refresh the list of variables when the window gains focus.
        function windowFocusGainedCallback(app)
            if ~isempty(app.problem)
                app.problem.refreshInputsFromWorkspace();
            end
        end
        
        %% ispackage Attempts to determine if the selected folder is a package
        function result = ispackage(~, path)
            % TODO Do this better
            contents = dir(path);
            result = sum(contains({contents.name}, {'student', 'submission'})) == 2;
        end
                
        
    end
    
    methods (Access = public)
        
        %% getPackage Return a structure containing all the entered data
        %
        % Called by testCaseGenerator to get everything the user entered.
        %
        % Returns a structure containing the following fields:
        %   outBase
        %   functionPath
        %   inputNames
        %   inputValues
        %   supportingFiles
        %   bannedFunctions
        %   isRecursive
        %   numTestCases
        function pkg = getPackage(app)
%             subTypeObj = app.problem.getSubType(subType);
%             pkg = struct('outBase', subTypeObj.OutputBaseWords, 'functionPath', app.Problem.FunctionPath, ...
%                 'inputValues', subTypeObj.InputValues, 'supportingFiles', subTypeObj.SupportingFiles, ...
%                 'bannedFunctions', app.Problem.BannedFunctions, 'isRecursive', app.Problem.IsRecursive, ...
%                 'numTestCases', subTypeObj.NumTestCases, 'inputNames', app.SubTypeObj.InputNames);
            allBaseWords = {app.problem.SubmissionTypes.OutputBaseWords};
            inputValues = {app.problem.SubmissionTypes.InputValues};
            supFiles = {app.problem.SubmissionTypes.SupportingFiles};
            numTestCases = {app.problem.SubmissionTypes.NumTestCases};
            inputNames = {app.problem.SubmissionTypes.InputNames};
%             allNames = {app.problem.SubmissionTypes.InputNames};            
%             inputNames = {};
%             for i = 1:length(allNames)
%                 for j = 1:length(allNames{i})
%                     inputNames = [inputNames, allNames{i}{j}];
%                 end
%             end
            pkg = struct('outBase', allBaseWords, 'functionPath', app.problem.FunctionPath, ...
                'inputValues', inputValues, 'supportingFiles', supFiles, ...
                'bannedFunctions', {app.problem.BannedFunctions}, 'isRecursive', app.problem.IsRecursive, ...
                'numTestCases', numTestCases, 'inputNames', inputNames);
        end
        
    
    end

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));
%             cleanUp = onCleanup(@()(cd(pwd)));

            % certain fields should start out being disabled before a function is entered
            disableAllChildren(app, app.RubricTabGroup);
%             app.RubricTabGroup.Enable = false;

            % add variable refreshing on focus gained
            ww = mlapptools.getWebWindow(app.UIFigure);
            ww.FocusGained = @(type, data)(app.windowFocusGainedCallback);

            
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            % reset the path
            %             path(app.initialPath);
            cd(app.cleanupDir);
            app.delete();
            
        end

        % Menu selected function: AboutMenu
        function AboutMenuSelected(app, event)
            About;
        end

        % Button pushed function: FunctionBrowseButton
        function FunctionBrowseButtonPushed(app, event)
            [file, path] = uigetfile('*.m', 'Select function solution file');
            if ~isempty(file) && ~isempty(path) && ischar(file) && ischar(path)
                % user picked something, so can enable everything
                loadFunction(app, fullfile(path, file));
            end
            
            makeVisible(app);
            
        end

        % Button pushed function: CompileButton
        function CompileButtonPushed(app, event)
            finished = false;
            if (~app.LocalDiskCheckBox.Value && ~app.GoogleDriveCheckBox.Value) ...
                    || isempty(app.LocalOutputDir)
                % no output location selected!
                uiconfirm(app.UIFigure, 'You have to choose an output location!', ...
                    'Error', 'Icon', 'error');
            else
                finished = confirmEmpty(app, app.LocalOutputDir);
            end
            
            if finished
                testCaseGenerator(app);
            else
                % emulate pressing the browse button
                LocalBrowseButtonPushed(app);
                
            end
        end

        % Button pushed function: BannedFunctionsAddButton
        function BannedFunctionsAddButtonPushed(app, event)
            % adds a function to the banned functions list (if not already there)
            toAdd = app.BannedFunctionsEditField.Value;
            if ~(isempty(toAdd))
                % look for the added function in the list already
                % also, make sure the function exists as a .m file or a builtin
                if ~any(strcmp(toAdd, app.BannedFunctionsListBox.Items))
                    goAhead = true;
                    if ~(exist(toAdd, 'file') || exist(toAdd, 'builtin'))
                        choice = uiconfirm(app.UIFigure, ...
                            sprintf('%s() was not found on the current path.', toAdd), 'Warning', ...
                            'Icon', 'warning', 'Options', {'Add anyway', 'Cancel'});
                        if ~strcmp(choice, 'Add anyway')
                            goAhead = false;
                        end
                    end
                    if goAhead
                        app.BannedFunctionsListBox.Items = [app.BannedFunctionsListBox.Items, toAdd];
                        app.problem.BannedFunctions = app.BannedFunctionsListBox.Items;
                    end
                end
            end
            app.BannedFunctionsEditField.Value = '';
        end

        % Button pushed function: BannedFunctionsRemoveButton
        function BannedFunctionsRemoveButtonPushed(app, event)
            % remove a function from the banned functions listbox
            selected = app.BannedFunctionsListBox.Value;
            if ~isempty(selected)
                items = app.BannedFunctionsListBox.Items;
                items = items(~strcmp(items, selected));
                app.BannedFunctionsListBox.Items = items;
                app.problem.BannedFunctions = items;
            end
        end

        % Value changed function: RecursiveCheckBox
        function RecursiveCheckBoxValueChanged(app, event)
            value = app.RecursiveCheckBox.Value;
%             app.isRecursive = value;
            app.problem.IsRecursive = value;
        end

        % Button pushed function: OutputFolderBrowseButton
        function OutputFolderBrowseButtonPushed(app, event)
            browser = GoogleDriveBrowser(app, app.functionName);
            uiwait(browser.UIFigure);
            delete(browser);
            % TODO: verify that user actually picked a folder
        end

        % Callback function
        function RefreshVariablesButtonPushed(app, event)
            app.problem.refreshInputsFromWorkspace();
        end

        % Button pushed function: LocalBrowseButton
        function LocalBrowseButtonPushed(app, event)
            finished = false;
            while ~finished
                path = uigetdir('*.m', 'Select output destination');
                if ~isempty(path) && ischar(path)
                    app.LocalOutputDir = path;
                else
                    % cancel, no folder picked
                    app.makeVisible();
                    return;
                end
                app.makeVisible();
                finished = confirmEmpty(app, path);
            end
        end
        
        %% confirmEmpty Checks whether the selected output directory is empty 
        %               and deletes it when necessary.
        %
        % Returns false if the user needs to select another, or true if the
        % directory is empty OR the contents were deleted.
        function finished = confirmEmpty(app, path)
            if ~app.exportLocalSelected
                finished = true;
            else
                finished = false;
                filesInside = dir([path filesep '*.m']);
                filesInside = {filesInside.name};
                isSameProblem = length(filesInside) == 1 ...
                    && ispackage(app, path) ...
                    && (isequal(filesInside{1}, [app.problem.FunctionName, '.m']) ...
                        || isequal(strrep(filesInside{1}, '.m', '_soln'), app.problem.FunctionName));

                % warn if not empty
                if length(dir(path)) > 2 && ~isSameProblem
                    choice = uiconfirm(app.UIFigure, ...
                        sprintf('The contents of %s will be deleted.', path), 'Directory not empty', ...
                        'Icon', 'warning', 'Options', {'OK', 'Choose another output folder'});
                    if strcmp(choice, 'OK')
                        % delete contents of folder
                        [~, name] = fileparts(path);
                        state = warning('off', 'MATLAB:RMDIR:RemovedFromPath');
                        rmdir(path, 's');
                        % recreate empty folder
                        mkdir(name);
                        finished = true;
                        % restore old warning state
                        warning(state);
                    end
                else
                    % is empty, so all good
                    finished = true;
                end
            end
        end

        % Value changed function: LocalDiskCheckBox
        function LocalDiskCheckBoxValueChanged(app, event)
            value = app.LocalDiskCheckBox.Value;
            if value
                txt = 'on';
            else
                txt = 'off';
            end
            app.LocalBrowseButton.Enable = txt;
            app.exportLocalSelected = value;
        end

        % Value changed function: GoogleDriveCheckBox
        function GoogleDriveCheckBoxValueChanged(app, event)
            value = app.GoogleDriveCheckBox.Value;
            if value
                txt = 'on';
            else
                txt = 'off';
            end
            app.OutputFolderBrowseButton.Enable = txt;
            app.exportDriveSelected = value;
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)
            % get all component positions from the layout
            layoutApp = TestCaseCompiler_Layout;
            layout = layoutApp.getLayout();
            app.Layout = layout;
            delete(layoutApp);

            % Create UIFigure
            app.UIFigure = uifigure;
%             app.UIFigure.Position = [100 100 701 474];
            app.UIFigure.Position = layout.UIFigure;
            app.UIFigure.Name = 'CS1371 Test Case Generator';
            app.UIFigure.Resize = 'off';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create HelpMenu
            app.HelpMenu = uimenu(app.UIFigure);
            app.HelpMenu.Text = 'Help';

            % Create HelpMenu_2
            app.HelpMenu_2 = uimenu(app.HelpMenu);
            app.HelpMenu_2.Text = 'Help';

            % Create AboutMenu
            app.AboutMenu = uimenu(app.HelpMenu);
            app.AboutMenu.MenuSelectedFcn = createCallbackFcn(app, @AboutMenuSelected, true);
            app.AboutMenu.Text = 'About';

            % Create RubricTabGroup
            app.RubricTabGroup = uitabgroup(app.UIFigure);
%             app.RubricTabGroup.Position = [11 5 680 330];
            app.RubricTabGroup.Position = layout.RubricTabGroup;


            % Create StudentTab
            app.StudentTab = uitab(app.RubricTabGroup);
            app.StudentTab.Title = '? Student';

            % Create StudentSupportingFilesPanel
            app.StudentSupportingFilesPanel = uipanel(app.StudentTab);
            app.StudentSupportingFilesPanel.Title = 'Supporting Files';
%             app.StudentSupportingFilesPanel.Position = [11 202 370 94];
            app.StudentSupportingFilesPanel.Position = layout.SupportingFilesPanel;


            % Create StudentSupportingFilesAddButton
            app.StudentSupportingFilesAddButton = uibutton(app.StudentSupportingFilesPanel, 'push');
            app.StudentSupportingFilesAddButton.BackgroundColor = [0.902 0.902 0.902];
%             app.StudentSupportingFilesAddButton.Position = [261 42 100 22];
            app.StudentSupportingFilesAddButton.Position = layout.SupportingFilesAddButton;
            app.StudentSupportingFilesAddButton.Text = 'Add...';

            % Create StudentSupportingFilesRemoveButton
            app.StudentSupportingFilesRemoveButton = uibutton(app.StudentSupportingFilesPanel, 'push');
            app.StudentSupportingFilesRemoveButton.BackgroundColor = [0.902 0.902 0.902];
%             app.StudentSupportingFilesRemoveButton.Position = [261 12 100 22];
            app.StudentSupportingFilesRemoveButton.Position = layout.SupportingFilesRemoveButton;
            app.StudentSupportingFilesRemoveButton.Text = 'Remove';

            % Create StudentSupportingFilesListBox
            app.StudentSupportingFilesListBox = uilistbox(app.StudentSupportingFilesPanel);
            app.StudentSupportingFilesListBox.Items = {};
            app.StudentSupportingFilesListBox.FontName = 'Consolas';
%             app.StudentSupportingFilesListBox.Position = [10 14 241 50];
            app.StudentSupportingFilesListBox.Position = layout.SupportingFilesListBox;
            app.StudentSupportingFilesListBox.Value = {};

            % Create StudentValuesTabGroup
            app.StudentValuesTabGroup = uitabgroup(app.StudentTab);
%             app.StudentValuesTabGroup.Position = [11 55 660 138];
            app.StudentValuesTabGroup.Position = layout.ValuesTabGroup;

            % Create StudentTestCase1Tab
            app.StudentTestCase1Tab = uitab(app.StudentValuesTabGroup);
            app.StudentTestCase1Tab.Title = 'Test Case 1';

            % Create StudentOutputBaseWordsPanel
            app.StudentOutputBaseWordsPanel = uipanel(app.StudentTab);
            app.StudentOutputBaseWordsPanel.Title = 'Output Base Words';
%             app.StudentOutputBaseWordsPanel.Position = [391 202 280 94];
            app.StudentOutputBaseWordsPanel.Position = layout.OutputBaseWordsPanel;

            % Create StudentOutputBaseWordsEditField
            app.StudentOutputBaseWordsEditField = uieditfield(app.StudentOutputBaseWordsPanel, 'text');
            app.StudentOutputBaseWordsEditField.FontName = 'Consolas';
%             app.StudentOutputBaseWordsEditField.Position = [21 28 238 22];
            app.StudentOutputBaseWordsEditField.Position = layout.OutputBaseWordsEditField;

            % Create StudentRemoveTestCaseButton
            app.StudentRemoveTestCaseButton = uibutton(app.StudentTab, 'push');
            app.StudentRemoveTestCaseButton.FontName = 'Courier New';
            app.StudentRemoveTestCaseButton.Enable = 'off';
%             app.StudentRemoveTestCaseButton.Position = [51 13 31 22];
            app.StudentRemoveTestCaseButton.Position = layout.RemoveTestCaseButton;
            app.StudentRemoveTestCaseButton.Text = '-';

            % Create StudentAddTestCaseButton
            app.StudentAddTestCaseButton = uibutton(app.StudentTab, 'push');
            app.StudentAddTestCaseButton.FontName = 'Courier New';
%             app.StudentAddTestCaseButton.Position = [11 13 31 22];
            app.StudentAddTestCaseButton.Position = layout.AddTestCaseButton;
            app.StudentAddTestCaseButton.Text = '+';

            % Create CompileButton
            app.CompileButton = uibutton(app.UIFigure, 'push');
            app.CompileButton.ButtonPushedFcn = createCallbackFcn(app, @CompileButtonPushed, true);
%             app.CompileButton.Position = [571 11 100 24];
            app.CompileButton.Position = layout.CompileButton;
            app.CompileButton.Text = '? Compile!';

            % Create ProblemSettingsPanel
            app.ProblemSettingsPanel = uipanel(app.UIFigure);
            app.ProblemSettingsPanel.Title = 'Problem Settings';
%             app.ProblemSettingsPanel.Position = [411 345 280 120];
            app.ProblemSettingsPanel.Position = layout.ProblemSettingsPanel;

            % Create RecursiveCheckBox
            app.RecursiveCheckBox = uicheckbox(app.ProblemSettingsPanel);
            app.RecursiveCheckBox.ValueChangedFcn = createCallbackFcn(app, @RecursiveCheckBoxValueChanged, true);
            app.RecursiveCheckBox.Enable = 'off';
            app.RecursiveCheckBox.Text = 'Recursive?';
%             app.RecursiveCheckBox.Position = [12 7 90 22];
            app.RecursiveCheckBox.Position = layout.RecursiveCheckBox;

            % Create BannedFunctionsLabel
            app.BannedFunctionsLabel = uilabel(app.ProblemSettingsPanel);
            app.BannedFunctionsLabel.HorizontalAlignment = 'center';
            app.BannedFunctionsLabel.Enable = 'off';
%             app.BannedFunctionsLabel.Position = [10 68 102 22];
            app.BannedFunctionsLabel.Position = layout.BannedFunctionsLabel;
            app.BannedFunctionsLabel.Text = 'Banned Functions';

            % Create BannedFunctionsListBox
            app.BannedFunctionsListBox = uilistbox(app.ProblemSettingsPanel);
            app.BannedFunctionsListBox.Items = {};
            app.BannedFunctionsListBox.Enable = 'off';
            app.BannedFunctionsListBox.FontName = 'Consolas';
%             app.BannedFunctionsListBox.Position = [170 40 95 50];
            app.BannedFunctionsListBox.Position = layout.BannedFunctionsListBox;

            app.BannedFunctionsListBox.Value = {};

            % Create BannedFunctionsAddButton
            app.BannedFunctionsAddButton = uibutton(app.ProblemSettingsPanel, 'push');
            app.BannedFunctionsAddButton.ButtonPushedFcn = createCallbackFcn(app, @BannedFunctionsAddButtonPushed, true);
            app.BannedFunctionsAddButton.Enable = 'off';
%             app.BannedFunctionsAddButton.Position = [101 38 60 22];
            app.BannedFunctionsAddButton.Position = layout.BannedFunctionsAddButton;

            app.BannedFunctionsAddButton.Text = 'Add';

            % Create BannedFunctionsRemoveButton
            app.BannedFunctionsRemoveButton = uibutton(app.ProblemSettingsPanel, 'push');
            app.BannedFunctionsRemoveButton.ButtonPushedFcn = createCallbackFcn(app, @BannedFunctionsRemoveButtonPushed, true);
            app.BannedFunctionsRemoveButton.Enable = 'off';
%             app.BannedFunctionsRemoveButton.Position = [170 8 95 22];
            app.BannedFunctionsRemoveButton.Position = layout.BannedFunctionsRemoveButton;

            app.BannedFunctionsRemoveButton.Text = 'Remove';

            % Create BannedFunctionsEditField
            app.BannedFunctionsEditField = uieditfield(app.ProblemSettingsPanel, 'text');
            app.BannedFunctionsEditField.FontName = 'Consolas';
            app.BannedFunctionsEditField.Enable = 'off';
%             app.BannedFunctionsEditField.Position = [11 38 80 22];
            app.BannedFunctionsEditField.Position = layout.BannedFunctionsEditField;


            % Create GeneralPanel
            app.GeneralPanel = uipanel(app.UIFigure);
            app.GeneralPanel.Title = 'General';
%             app.GeneralPanel.Position = [11 345 390 120];
            app.GeneralPanel.Position = layout.GeneralPanel;


            % Create FunctionLabel
            app.FunctionLabel = uilabel(app.GeneralPanel);
%             app.FunctionLabel.Position = [11 68 55 22];
            app.FunctionLabel.Position = layout.FunctionLabel;

            app.FunctionLabel.Text = 'Function:';

            % Create FunctionBrowseButton
            app.FunctionBrowseButton = uibutton(app.GeneralPanel, 'push');
            app.FunctionBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @FunctionBrowseButtonPushed, true);
%             app.FunctionBrowseButton.Position = [71 68 70 22];
            app.FunctionBrowseButton.Position = layout.FunctionBrowseButton;
            app.FunctionBrowseButton.Text = 'Browse...';

            % Create SavetoLabel
            app.SavetoLabel = uilabel(app.GeneralPanel);
%             app.SavetoLabel.Position = [151 68 50 22];
            app.SavetoLabel.Position = layout.SavetoLabel;
            app.SavetoLabel.Text = 'Save to:';

            % Create OutputFolderBrowseButton
            app.OutputFolderBrowseButton = uibutton(app.GeneralPanel, 'push');
            app.OutputFolderBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @OutputFolderBrowseButtonPushed, true);
%             app.OutputFolderBrowseButton.Position = [306 28 70 22];
            app.OutputFolderBrowseButton.Position = layout.OutputFolderBrowseButton;
            app.OutputFolderBrowseButton.Text = 'Browse...';

            % Create FunctionNameField
            app.FunctionNameField = uieditfield(app.GeneralPanel, 'text');
            app.FunctionNameField.Editable = 'off';
%             app.FunctionNameField.Position = [11 28 190 22];
            app.FunctionNameField.Position = layout.FunctionNameField;
            app.FunctionNameField.Value = 'No problem selected!';

            % Create LocalDiskCheckBox
            app.LocalDiskCheckBox = uicheckbox(app.GeneralPanel);
            app.LocalDiskCheckBox.ValueChangedFcn = createCallbackFcn(app, @LocalDiskCheckBoxValueChanged, true);
            app.LocalDiskCheckBox.Text = 'Local disk';
%             app.LocalDiskCheckBox.Position = [211 68 75 22];
            app.LocalDiskCheckBox.Position = layout.LocalDiskCheckBox;

            % Create GoogleDriveCheckBox
            app.GoogleDriveCheckBox = uicheckbox(app.GeneralPanel);
            app.GoogleDriveCheckBox.ValueChangedFcn = createCallbackFcn(app, @GoogleDriveCheckBoxValueChanged, true);
            app.GoogleDriveCheckBox.Text = 'Google Drive';
%             app.GoogleDriveCheckBox.Position = [211 28 92 22];
            app.GoogleDriveCheckBox.Position = layout.GoogleDriveCheckBox;
            app.GoogleDriveCheckBox.Value = true;

            % Create LocalBrowseButton
            app.LocalBrowseButton = uibutton(app.GeneralPanel, 'push');
            app.LocalBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @LocalBrowseButtonPushed, true);
            app.LocalBrowseButton.Enable = 'off';
%             app.LocalBrowseButton.Position = [306 68 70 22];
            app.LocalBrowseButton.Position = layout.LocalBrowseButton;
            app.LocalBrowseButton.Text = 'Browse...';
        end
    end

    methods (Access = public)

        % Construct app
        function app = TestCaseCompiler

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end