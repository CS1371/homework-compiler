classdef TestCaseCompiler < matlab.apps.AppBase
    
    % Properties that correspond to app components
    properties (Access = public)
        % Parent uifig
        UIFigure                       matlab.ui.Figure
        
        % The menubar
        Menu                           matlab.ui.container.Menu
        QuitMenu                       matlab.ui.container.Menu
        HelpMenu                       matlab.ui.container.Menu
        HelpMenu_2                     matlab.ui.container.Menu
        AboutMenu                      matlab.ui.container.Menu
        
        % TabGroup that holds all the rubrics (student, submission, resub)
        RubricTabGroup                 matlab.ui.container.TabGroup
        
        %         StudentTab                     matlab.ui.container.Tab
        %         StudentSupportingFilesPanel    matlab.ui.container.Panel
        %         StudentSupportingFilesAddButton  matlab.ui.control.Button
        %         StudentSupportingFilesRemoveButton  matlab.ui.control.Button
        %         StudentSupportingFilesListBox  matlab.ui.control.ListBox
        %         StudentValuesTabGroup          matlab.ui.container.TabGroup
        %         StudentTestCase1Tab            matlab.ui.container.Tab
        %         StudentOutputBaseWordsPanel    matlab.ui.container.Panel
        %         StudentOutputBaseWordsEditField  matlab.ui.control.EditField
        %         StudentRemoveTestCaseButton    matlab.ui.control.Button
        %         StudentAddTestCaseButton       matlab.ui.control.Button
        
        % Button to compile
        CompileButton                  matlab.ui.control.Button
        
        % Problem settings: banned functions and recursion
        ProblemSettingsPanel           matlab.ui.container.Panel
        RecursiveCheckBox              matlab.ui.control.CheckBox
        BannedFunctionsLabel           matlab.ui.control.Label
        BannedFunctionsListBox         matlab.ui.control.ListBox
        BannedFunctionsAddButton       matlab.ui.control.Button
        BannedFunctionsRemoveButton    matlab.ui.control.Button
        BannedFunctionsEditField       matlab.ui.control.EditField
        
        %         FunctionLabel                  matlab.ui.control.Label
        
        % Where the function saves to
        SaveLocationPanel              matlab.ui.container.Panel
        LocalBrowseButton              matlab.ui.control.Button
        OutputFolderBrowseButton       matlab.ui.control.Button
        
        % Function browse panel
        FunctionBrowsePanel            matlab.ui.container.Panel
        FunctionBrowseButton           matlab.ui.control.Button
        FunctionDriveBrowseButton      matlab.ui.control.Button
        
        % Status bar stuff
        LocalOutputLabel               matlab.ui.control.Label
        LocalOutputEditField           matlab.ui.control.EditField
        GoogleDriveLabel               matlab.ui.control.Label
        GoogleDriveEditField           matlab.ui.control.EditField
        DriveOutputClearButton         matlab.ui.control.Button
        LocalOutputClearButton         matlab.ui.control.Button

        
    end
    
    
    properties (Access = public, Constant)
        GOOD_COLOR = [0.25 1 0.25];
%         ERROR_SYMBOL = TestCaseCompiler_Layout.ERROR_ICON; % Global error symbol, used to illustrate test case verification failure
    end
    
    properties (Hidden)
        % Auth stuff
        % used by the google drive browser when GoogleDriveBrowser() is called.
        token
        folderId
        folderName;
        clientKey
        clientId
        clientSecret
        
        % user-selected path to local output
        LocalOutputDir char
        
        % directory for cleanup
        cleanupDir = cd()
        
        % structure of positions for all the components, by name
        Layout struct
        
    end
    
    properties (Access = private)
        % problem object. holds everything.
        problem Problem
        
        % default name for the window
        DefaultName char = 'CS1371 Test Case Compiler';
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
            clear TestCase;
            try
                delete(app.RubricTabGroup.Children);
                app.BannedFunctionsListBox.Items = {};
                app.RecursiveCheckBox.Value = false;
                if app.ispackage(cd())
                    % load the package
                    app.problem = Problem(path, app.RubricTabGroup, app.Layout);
                    app.problem.loadFromPackage(cd, app.RubricTabGroup, app);
                    app.LocalOutputDir = fileparts(app.problem.FunctionPath);
                    
                else
                    % create a new problem
                    app.problem = Problem(path, app.RubricTabGroup, app.Layout);
                    app.LocalOutputDir = '';
                    app.folderId = '';
                end
            catch ME
                cd(origDir);
                % if for some reason the function is invalid (selected a script, invalid path, etc)
                % then disable all the global problem settings fields and present an error message
                uiconfirm(app.UIFigure, ...
                    sprintf('Error: %s\n%s line %d', ME.message, ME.stack(1).file, ME.stack(1).line), ...
                    'Function load error', 'Options', {'OK'}, 'Icon', 'error');
                
                % make the edit field red
                %                 app.FunctionNameField.BackgroundColor = [1.0 0 0];
                
                % compile button
                app.CompileButton.Enable = 'off';
                %                 app.RefreshVariablesButton.Enable = 'on';
                app.UIFigure.Name = app.DefaultName;
                return;
            end
            
            progBar.Value = 0.25;
            progBar.Message = 'Contacting MATLAB support...';
            progBar.Title = messages{randi([1 length(messages)])};
            
            
            % enable all the disabled fields
            %             [~, fnName] = fileparts(path);
            %             app.FunctionNameField.Value = app.problem.FunctionName;
            %             app.FunctionNameField.FontName = 'Consolas';
            %             app.FunctionNameField.BackgroundColor = [1 1 1];
            app.UIFigure.Name = [app.DefaultName, ' (', app.problem.FunctionName, ')'];
            
            % compile button
            app.CompileButton.Enable = 'on';
            %             app.RefreshVariablesButton.Enable = 'on';
            ind1 = find(contains({app.RubricTabGroup.Children.Title}, 'Student'));
            ind2 = find(contains({app.RubricTabGroup.Children.Title}, 'Submission'));
            ind3 = find(contains({app.RubricTabGroup.Children.Title}, 'Resubmission'));
            app.RubricTabGroup.Children = app.RubricTabGroup.Children([ind1 ind2 ind3]);
            app.RubricTabGroup.SelectedTab = app.RubricTabGroup.Children(1);
            % problem settings panel
            app.enableAllChildren(app.ProblemSettingsPanel);
            app.enableAllChildren(app.SaveLocationPanel);
            
            progBar.close();
            
            if app.PushIndex >= 8
               updateLabels(app); 
            end
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
        
%         function varargout = getDir(app, varargin)
%            varargout = uigetdir(varargin);
%            app.makeVisible();
%         end
%         
        
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
    
    methods
        %% LocalOutputDir
        % 
        % Sets the local output folder and the contents of the edit field.
        %
        % Sets the editfield to be green if not the default message, and
        % white otherwise.
        function set.LocalOutputDir(app, value)
            if isempty(value) || strcmp(value, app.Layout.LocalOutputEditField.Value) %#ok<*MCSUP>
                app.LocalOutputEditField.Value = app.Layout.LocalOutputEditField.Value;
                app.LocalOutputEditField.BackgroundColor = app.Layout.LocalOutputEditField.BackgroundColor;
                app.LocalOutputDir = '';
            else
                app.LocalOutputEditField.Value = abbreviate(value, 20);
                app.LocalOutputEditField.BackgroundColor = app.GOOD_COLOR;
                app.LocalOutputDir = value;
            end
        end
        
        %% folderName
        %
        % Sets the Google Drive folder name and the contents of the edit
        % field.
        %
        % See above.
        function set.folderName(app, value)
            if isempty(value)
                app.GoogleDriveEditField.Value = app.Layout.GoogleDriveEditField.Value;
                app.GoogleDriveEditField.BackgroundColor = app.Layout.GoogleDriveEditField.BackgroundColor;
            else
                app.GoogleDriveEditField.Value = abbreviate(value, 10);
                app.GoogleDriveEditField.BackgroundColor = app.GOOD_COLOR;
            end
            
            app.folderName = value;

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
            addpath(genpath(fileparts(mfilename('fullpath'))));
            %             cleanUp = onCleanup(@()(cd(pwd)));
            
            % certain fields should start out being disabled before a function is entered
            disableAllChildren(app, app.RubricTabGroup);
            disableAllChildren(app, app.SaveLocationPanel);
            app.CompileButton.Enable = 'off';
            %             app.RubricTabGroup.Enable = false;
            
            % add variable refreshing on focus gained
            ww = mlapptools.getWebWindow(app.UIFigure);
            ww.FocusGained = @(type, data)(app.windowFocusGainedCallback);
            app.makeVisible();
            
        end
        
        % Close request function: UIFigure
        function UIFigureCloseRequest(app, ~)
            % reset the path
            %             path(app.initialPath);
            cd(app.cleanupDir);
            app.delete();
            
        end
        
        % Menu selected function: AboutMenu
        function AboutMenuSelected(app, ~)
%             About;
            aboutWindow = uifigure();
            aboutWindow.Position = [100 100 640 480];
            aboutWindow.Name = 'About';

            % Create TitleLabel
            aboutTitleLabel = uilabel(aboutWindow);
            aboutTitleLabel.HorizontalAlignment = 'center';
            aboutTitleLabel.FontName = 'Consolas';
            aboutTitleLabel.FontSize = 36;
            aboutTitleLabel.Position = [31 361 570 90];
            aboutTitleLabel.Text = 'CS1371 Test Case Generator';

            % Create VersionLabel
            aboutVersionLabel = uilabel(aboutWindow);
            aboutVersionLabel.HorizontalAlignment = 'center';
            aboutVersionLabel.FontName = 'Consolas';
            aboutVersionLabel.FontSize = 24;
            aboutVersionLabel.Position = [31 331 570 60];
            aboutVersionLabel.Text = 'v1.0';

            % Create SloganLabel
            aboutSloganLabel = uilabel(aboutWindow);
            aboutSloganLabel.HorizontalAlignment = 'center';
            aboutSloganLabel.FontName = 'Consolas';
            aboutWindow.ButtonDownFcn = @(a, ev)(app.doThing());
            aboutSloganLabel.FontSize = 24;
            aboutSloganLabel.Position = [31 211 600 60];
            aboutSloganLabel.Text = '"HTTMTHTDW"';

            % Create SignatureLabel
            aboutSignatureLabel = uilabel(aboutWindow);
            aboutSignatureLabel.HorizontalAlignment = 'right';
            aboutSignatureLabel.FontName = 'Consolas';
            aboutSignatureLabel.FontSize = 20;
            aboutSignatureLabel.Position = [121 151 480 60];
            aboutSignatureLabel.Text = '-A.S., 2018';

            % Create CreditsLabel
            aboutCreditsLabel = uilabel(aboutWindow);
            aboutCreditsLabel.HorizontalAlignment = 'center';
            aboutCreditsLabel.FontName = 'Consolas';
            aboutCreditsLabel.FontSize = 11;
            aboutCreditsLabel.Position = [82 1 468 30];
            aboutCreditsLabel.Text = '(c) 2018 CS1371 (J. Htay, D. Profili, A. Rao, H. White)';
            

        end
        
        % Button pushed function: FunctionBrowseButton
        function FunctionBrowseButtonPushed(app, ~)
            [file, path] = uigetfile('*.m', 'Select function solution file');
            if ~isempty(file) && ~isempty(path) && ischar(file) && ischar(path)
                % user picked something, so can enable everything
                loadFunction(app, fullfile(path, file));
            end
            
            makeVisible(app);
            
        end
        
        % Button pushed function: CompileButton
        function CompileButtonPushed(app, ~)
            finished = false;
            if isempty(app.LocalOutputDir) && isempty(app.folderId)
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
        
        function updateLabels(app)
            function centerLabels(parent)
                fields = {};
                if isprop(parent, 'Title')
                    fields = [fields 'Title'];
                elseif isprop(parent, 'Text')
                    fields = [fields, 'Text'];
                elseif isprop(parent, 'Name')
                    fields = [fields, 'Name'];
                end

                for f = 1:length(fields)
                    temp = parent.(fields{f});
                    temp = strrep(temp, char(98), TestCaseCompiler_Layout.MISC_ICON);
                    temp = strrep(temp, char(66), TestCaseCompiler_Layout.MISC_ICON);
                    parent.(fields{f}) = temp;
                end
                
                if isprop(parent, 'Children') && ~isempty(parent.Children)
                    for c = 1:length(parent.Children)
                        centerLabels(parent.Children(c));
                    end
                end
            end
            
            centerLabels(app.UIFigure);
        end
        
        % Button pushed function: BannedFunctionsAddButton
        function BannedFunctionsAddButtonPushed(app, ~)
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
        function BannedFunctionsRemoveButtonPushed(app, ~)
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
        function RecursiveCheckBoxValueChanged(app, ~)
            value = app.RecursiveCheckBox.Value;
            %             app.isRecursive = value;
            if value
                % check recursion
                if ~checkRecur(app.problem.FunctionPath)
                    % warn and undo
                    value = false;
                    app.RecursiveCheckBox.Value = value;
                    uialert(app.UIFigure, 'Your solution is not recursive!', 'Recursion Error');
                end
            end
            app.problem.IsRecursive = value;
        end
        
        % Button pushed function: OutputFolderBrowseButton
        function OutputFolderBrowseButtonPushed(app, ~)
            tokenPath = [fileparts(mfilename('fullpath')) filesep 'google.token'];
            fid = fopen(tokenPath, 'rt');
            if fid == -1
                throw(MException('ASSIGNMENTCOMPILER:authorization:notEnoughCredentials', ...
                    'For initial authorization, you must provide all credentials'));
            else
                lines = char(fread(fid)');
                fclose(fid);
                % line 1 will be id, 2 secret, 3 key, 4 token
                lines = strsplit(lines, newline);
                if numel(lines) == 3
                    % need to authorize
                    [app.clientId, app.clientSecret, app.clientKey] = deal(lines{:});
                    app.token = authorizeWithGoogle(app.clientId, app.clientSecret);
                    fid = fopen(tokenPath, 'wt');
                    lines{end+1} = app.token;
                    fwrite(fid, strjoin(lines, newline));
                    fclose(fid);
                else
                    [app.clientId, app.clientSecret, app.clientKey, app.token] = deal(lines{:});
                end
            end
            accessToken = refresh2access(app.token, app.clientId, app.clientSecret);
            browser = GoogleDriveBrowser(accessToken);
            uiwait(browser.UIFigure);
            if isvalid(browser) && ~isempty(browser.selectedId)
                app.folderId = browser.selectedId;
                app.folderName = browser.selectedName;
                % In this case, we will only select a HOMEWORK folder -
                % _editing_ an existing one would be handled by browsing
                % for the input file. Right. RIGHT?!
            end
            delete(browser);
        end
        
        % Callback function
        function RefreshVariablesButtonPushed(app, ~)
            app.problem.refreshInputsFromWorkspace();
        end
        
        % Button pushed function: LocalBrowseButton
        function LocalBrowseButtonPushed(app, ~)
            finished = false;
            while ~finished
                path = uigetdir('*.m', 'Select output destination');
                if ~isempty(path) && ischar(path) % if user chose something
%                     app.LocalOutputDir = path;
                    [finished, app.LocalOutputDir] = confirmEmpty(app, path);
                else % cancel pressed
                    % cancel, no folder picked
                    app.makeVisible();
%                     if ~isempty(app.LocalOutputDir)
%                         app.LocalOutputDir = app.Layout.LocalOutputEditField.Value;
%                         app.LocalOutputEditField.Value = app.Layout.LocalOutputEditField.Value;
%                         app.LocalOutputEditField.BackgroundColor = app.Layout.LocalOutputEditField.BackgroundColor;
%                     end
                    finished = true;
                end
            end
            app.makeVisible();

            
%             app.LocalOutputEditField.Value = abbreviate(app.LocalOutputDir, 30);
%             app.LocalOutputEditField.BackgroundColor = app.GOOD_COLOR;
        end
        
        function FunctionDriveBrowseButtonPushed(app, ~)
            tokenPath = [fileparts(mfilename('fullpath')) filesep 'google.token'];
            fid = fopen(tokenPath, 'rt');
            if fid == -1
                throw(MException('ASSIGNMENTCOMPILER:authorization:notEnoughCredentials', ...
                    'For initial authorization, you must provide all credentials'));
            else
                lines = char(fread(fid)');
                fclose(fid);
                % line 1 will be id, 2 secret, 3 key, 4 token
                lines = strsplit(lines, newline);
                if numel(lines) == 3
                    % need to authorize
                    [app.clientId, app.clientSecret, app.clientKey] = deal(lines{:});
                    app.token = authorizeWithGoogle(app.clientId, app.clientSecret);
                    fid = fopen(tokenPath, 'wt');
                    lines{end+1} = app.token;
                    fwrite(fid, strjoin(lines, newline));
                    fclose(fid);
                else
                    [app.clientId, app.clientSecret, app.clientKey, app.token] = deal(lines{:});
                end
            end
            accessToken = refresh2access(app.token, app.clientId, app.clientSecret);
            browser = GoogleDriveBrowser(accessToken);
            browser.Title.Text = 'Select the problem folder (i.e., "myProblem")';
            uiwait(browser.UIFigure);
            if isvalid(browser) && ~isempty(browser.selectedId)
                p = uiprogressdlg(browser.UIFigure, ...
                    'Message', 'Downloading...', ...
                    'Title', 'Test Case Compiler', ...
                    'Indeterminate', 'on', ...
                    'Cancelable', 'off', ...
                    'ShowPercentage', 'off');
                tmp = browser.selectedId;
                name = browser.selectedName;
                % create local archive
                % get parent (since that's where we're uploading...)
                API = 'https://www.googleapis.com/drive/v3/files/';
                opts = weboptions();
                opts.HeaderFields = {'Authorization', ['Bearer ' accessToken]};
                try
                    contents = webread([API tmp '?fields=parents'], opts);
                    parentId = contents.parents{1};
                    % now get the name
                    contents = webread([API parentId '?fields=name'], opts);
                    parentName = contents.name;
                catch reason
                    e = MException('AUTOGRADER:networking:connectionError', ...
                        'Connection was terminated (Are you connected to the internet?');
                    e = e.addCause(reason);
                    throw(e);
                end
                workFolder = tempname;
                mkdir(workFolder);
                cd(workFolder);
                downloadFromDrive(tmp, accessToken, workFolder, app.clientKey);
                delete(browser);
                p.Message = 'Parsing Package Information...';
                app.loadFunction(fullfile(pwd, [name '.m']));
                % set name in status bar
                app.folderId = parentId;
                app.folderName = parentName;
                close(p);
            else
                app.GoogleDriveEditField.Value = app.Layout.GoogleDriveEditField.Value;
                app.GoogleDriveEditField.BackgroundColor = app.Layout.GoogleDriveEditField.BackgroundColor;
                delete(browser);
            end
            
        end
        
        %% confirmEmpty Checks whether the selected output directory is empty
        %               and deletes it when necessary.
        %
        % Returns false if the user needs to select another, or true if the
        % directory is empty OR the contents were deleted.
        function [finished, newPath] = confirmEmpty(app, path)
            % TODO - put the while loop in here
            if isempty(path)
                finished = true;
                newPath = '';
            else
                finished = false;
                filesInside = dir([path filesep '*.m']);
                filesInside = {filesInside.name};
                % a folder is considered the same problem if there is one m
                % file, the folder is a package (see ispackage()), and the
                % single file matches the name of the current function name
                % (disregarding any _soln).
                isSameProblem = length(filesInside) == 1 ...
                    && ispackage(app, path) ...
                    && (isequal(filesInside{1}, [app.problem.FunctionName, '.m']) ...
                    || isequal(strrep(filesInside{1}, '.m', '_soln'), app.problem.FunctionName));
                
                % If not empty and not the same problem, do a warning
                if length(dir(path)) > 2 && ~isSameProblem
                    app.makeVisible();
                    choice = uiconfirm(app.UIFigure, ...
                        sprintf('The contents of "%s" will be deleted.', path), 'Directory not empty', ...
                        'Icon', 'warning', 'Options', {'OK', 'Cancel'});
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
                        newPath = path;
                    elseif strcmp(choice, 'Cancel')
                        % Canceled - quit
                        finished = true;
                        newPath = app.LocalOutputDir;
                    end
                else
                    % is empty or same problem, so all good
                    finished = true;
                    newPath = path;
                end
            end
        end
        
        function doThing(app)
            app.PushIndex = app.PushIndex + 1;
            if app.PushIndex >= 8
                updateLabels(app);
            end
        end
        
    end
    
    % App initialization and construction
    methods (Access = private)
        
        % Create UIFigure and components
        function createComponents(app)
            % get all component positions from the layout
            layoutApp = TestCaseCompiler_Layout;
            layout = layoutApp.getLayout({'Name', 'Text', 'Value', 'Position', 'FontName', ...
                'BackgroundColor', 'Enable', 'HorizontalAlignment', 'Items', 'Title', ...
                'FontSize', 'Label'});
            app.Layout = layout;
            delete(layoutApp);
            
            
            % Create UIFigure
            app.UIFigure = uifigure;
            %             app.UIFigure.Position = [100 100 701 474];
            %             app.UIFigure.Position = layout.UIFigure.Position;
            %             app.UIFigure.Name = 'CS1371 Test Case Generator';
            app.UIFigure.Resize = 'off';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
            copyFrom(app.UIFigure, layout.UIFigure, {'Position'});
            app.UIFigure.Name = app.DefaultName;
            % Create HelpMenu
            app.HelpMenu = uimenu(app.UIFigure);
%             app.HelpMenu.Text = 'Help';
            copyFrom(app.HelpMenu, layout.HelpMenu, {'Text'});
            
            % Create HelpMenu_2
            app.HelpMenu_2 = uimenu(app.HelpMenu);
%             app.HelpMenu_2.Text = 'Help';
            copyFrom(app.HelpMenu_2, layout.HelpMenu_2, {'Text'});
            
            % Create AboutMenu
            app.AboutMenu = uimenu(app.HelpMenu);
            app.AboutMenu.MenuSelectedFcn = createCallbackFcn(app, @AboutMenuSelected, true);
%             app.AboutMenu.Text = 'About';
            copyFrom(app.AboutMenu, layout.AboutMenu, {'Text'});
            
            
            % Create RubricTabGroup
            app.RubricTabGroup = uitabgroup(app.UIFigure);
            %             app.RubricTabGroup.Position = [11 5 680 330];
            %             app.RubricTabGroup.Position = layout.RubricTabGroup.Position;
            %             app.RubricTabGroup = copy(layout.RubricTabGroup);
            %             app.RubricTabGroup.Parent = app.UIFigure;
            copyFrom(app.RubricTabGroup, layout.RubricTabGroup, {'Position'});
            
            
            %             % Create StudentTab
            %             app.StudentTab = uitab(app.RubricTabGroup);
            %             app.StudentTab.Title = layout.SubTypeTab.Title;
            %
            %             % Create StudentSupportingFilesPanel
            %             app.StudentSupportingFilesPanel = uipanel(app.StudentTab);
            %             app.StudentSupportingFilesPanel.Title = 'Supporting Files';
            % %             app.StudentSupportingFilesPanel.Position = [11 202 370 94];
            %             app.StudentSupportingFilesPanel.Position = layout.SupportingFilesPanel.Position;
            %
            %
            %             % Create StudentSupportingFilesAddButton
            %             app.StudentSupportingFilesAddButton = uibutton(app.StudentSupportingFilesPanel, 'push');
            %             app.StudentSupportingFilesAddButton.BackgroundColor = [0.902 0.902 0.902];
            % %             app.StudentSupportingFilesAddButton.Position = [261 42 100 22];
            %             app.StudentSupportingFilesAddButton.Position = layout.SupportingFilesAddButton.Position;
            %             app.StudentSupportingFilesAddButton.Text = 'Add...';
            %
            %             % Create StudentSupportingFilesRemoveButton
            %             app.StudentSupportingFilesRemoveButton = uibutton(app.StudentSupportingFilesPanel, 'push');
            %             app.StudentSupportingFilesRemoveButton.BackgroundColor = [0.902 0.902 0.902];
            % %             app.StudentSupportingFilesRemoveButton.Position = [261 12 100 22];
            %             app.StudentSupportingFilesRemoveButton.Position = layout.SupportingFilesRemoveButton;
            %             app.StudentSupportingFilesRemoveButton.Text = 'Remove';
            %
            %             % Create StudentSupportingFilesListBox
            %             app.StudentSupportingFilesListBox = uilistbox(app.StudentSupportingFilesPanel);
            %             app.StudentSupportingFilesListBox.Items = {};
            %             app.StudentSupportingFilesListBox.FontName = 'Consolas';
            % %             app.StudentSupportingFilesListBox.Position = [10 14 241 50];
            %             app.StudentSupportingFilesListBox.Position = layout.SupportingFilesListBox.Position;
            %             app.StudentSupportingFilesListBox.Value = {};
            %
            %             % Create StudentValuesTabGroup
            %             app.StudentValuesTabGroup = uitabgroup(app.StudentTab);
            % %             app.StudentValuesTabGroup.Position = [11 55 660 138];
            %             app.StudentValuesTabGroup.Position = layout.ValuesTabGroup;
            %
            %             % Create StudentTestCase1Tab
            %             app.StudentTestCase1Tab = uitab(app.StudentValuesTabGroup);
            %             app.StudentTestCase1Tab.Title = 'Test Case 1';
            %
            %             % Create StudentOutputBaseWordsPanel
            %             app.StudentOutputBaseWordsPanel = uipanel(app.StudentTab);
            %             app.StudentOutputBaseWordsPanel.Title = 'Output Base Words';
            % %             app.StudentOutputBaseWordsPanel.Position = [391 202 280 94];
            %             app.StudentOutputBaseWordsPanel.Position = layout.OutputBaseWordsPanel;
            %
            %             % Create StudentOutputBaseWordsEditField
            %             app.StudentOutputBaseWordsEditField = uieditfield(app.StudentOutputBaseWordsPanel, 'text');
            %             app.StudentOutputBaseWordsEditField.FontName = 'Consolas';
            % %             app.StudentOutputBaseWordsEditField.Position = [21 28 238 22];
            %             app.StudentOutputBaseWordsEditField.Position = layout.OutputBaseWordsEditField;
            %
            %             % Create StudentRemoveTestCaseButton
            %             app.StudentRemoveTestCaseButton = uibutton(app.StudentTab, 'push');
            %             app.StudentRemoveTestCaseButton.FontName = 'Courier New';
            %             app.StudentRemoveTestCaseButton.Enable = 'off';
            % %             app.StudentRemoveTestCaseButton.Position = [51 13 31 22];
            %             app.StudentRemoveTestCaseButton.Position = layout.RemoveTestCaseButton;
            %             app.StudentRemoveTestCaseButton.Text = '-';
            %
            %             % Create StudentAddTestCaseButton
            %             app.StudentAddTestCaseButton = uibutton(app.StudentTab, 'push');
            %             app.StudentAddTestCaseButton.FontName = 'Courier New';
            %             app.StudentAddTestCaseButton.Position = [11 13 31 22];
            %             app.StudentAddTestCaseButton.Position = layout.AddTestCaseButton;
            %             app.StudentAddTestCaseButton.Text = '+';
            
            % Create CompileButton
            app.CompileButton = uibutton(app.UIFigure, 'push');
            copyFrom(app.CompileButton, layout.CompileButton, {'Position', 'Text'});
            %             app.CompileButton = copy(layout.CompileButton);
            %             app.CompileButton.Parent = app.UIFigure;
            app.CompileButton.ButtonPushedFcn = createCallbackFcn(app, @CompileButtonPushed, true);
            %             app.CompileButton.Position = [571 11 100 24];
            %             app.CompileButton.Position = layout.CompileButton.Position;
            %             app.CompileButton.Text = layout.CompileButton.Text;
            
            % Create ProblemSettingsPanel
            app.ProblemSettingsPanel = uipanel(app.UIFigure);
            copyFrom(app.ProblemSettingsPanel, layout.ProblemSettingsPanel, ...
                {'Title', 'Position'});
            %             app.ProblemSettingsPanel.Title = 'Problem Settings';
            %             app.ProblemSettingsPanel.Position = [411 345 280 120];
            %             app.ProblemSettingsPanel.Position = layout.ProblemSettingsPanel.Position;
            % Create FunctionBrowsePanel
            
            % Create RecursiveCheckBox
            app.RecursiveCheckBox = uicheckbox(app.ProblemSettingsPanel);
            app.RecursiveCheckBox.ValueChangedFcn = createCallbackFcn(app, @RecursiveCheckBoxValueChanged, true);
            copyFrom(app.RecursiveCheckBox, layout.RecursiveCheckBox, ...
                {'Enable', 'Text', 'Position'});
                        %             app.RecursiveCheckBox.Enable = 'off';
            %             app.RecursiveCheckBox.Text = 'Recursive?';
            % %             app.RecursiveCheckBox.Position = [12 7 90 22];
            %             app.RecursiveCheckBox.Position = layout.RecursiveCheckBox.Position;
            
            % Create BannedFunctionsLabel
            app.BannedFunctionsLabel = uilabel(app.ProblemSettingsPanel);
            copyFrom(app.BannedFunctionsLabel, layout.BannedFunctionsLabel, ...
                {'HorizontalAlignment', 'Enable', 'Position', 'Text'});
            %             app.BannedFunctionsLabel.HorizontalAlignment = 'center';
            %             app.BannedFunctionsLabel.Enable = 'off';
            %             app.BannedFunctionsLabel.Position = [10 68 102 22];
            %             app.BannedFunctionsLabel.Position = layout.BannedFunctionsLabel.Position;
            %             app.BannedFunctionsLabel.Text = 'Banned Functions';
            
            % Create BannedFunctionsListBox
            app.BannedFunctionsListBox = uilistbox(app.ProblemSettingsPanel);
            copyFrom(app.BannedFunctionsListBox, layout.BannedFunctionsListBox, ...
                {'Items', 'Enable', 'FontName', 'Position', 'Value'});
            %             app.BannedFunctionsListBox.Items = {};
            %             app.BannedFunctionsListBox.Enable = 'off';
            %             app.BannedFunctionsListBox.FontName = 'Consolas';
            %             app.BannedFunctionsListBox.Position = [170 40 95 50];
            %             app.BannedFunctionsListBox.Position = layout.BannedFunctionsListBox.Position;
            
            %             app.BannedFunctionsListBox.Value = {};
            
            % Create BannedFunctionsAddButton
            app.BannedFunctionsAddButton = uibutton(app.ProblemSettingsPanel, 'push');
            app.BannedFunctionsAddButton.ButtonPushedFcn = createCallbackFcn(app, @BannedFunctionsAddButtonPushed, true);
            copyFrom(app.BannedFunctionsAddButton, layout.BannedFunctionsAddButton, ...
                {'Enable', 'Position', 'Text'});
            %             app.BannedFunctionsAddButton.Enable = 'off';
            %             app.BannedFunctionsAddButton.Position = [101 38 60 22];
            %             app.BannedFunctionsAddButton.Position = layout.BannedFunctionsAddButton.Position;
            
            %             app.BannedFunctionsAddButton.Text = 'Add';
            
            % Create BannedFunctionsRemoveButton
            app.BannedFunctionsRemoveButton = uibutton(app.ProblemSettingsPanel, 'push');
            app.BannedFunctionsRemoveButton.ButtonPushedFcn = createCallbackFcn(app, @BannedFunctionsRemoveButtonPushed, true);
            copyFrom(app.BannedFunctionsRemoveButton, layout.BannedFunctionsRemoveButton, ...
                {'Enable', 'Position', 'Text'});
            %             app.BannedFunctionsRemoveButton.Enable = 'off';
            %             app.BannedFunctionsRemoveButton.Position = [170 8 95 22];
            %             app.BannedFunctionsRemoveButton.Position = layout.BannedFunctionsRemoveButton.Position;
            
            %             app.BannedFunctionsRemoveButton.Text = 'Remove';
            
            % Create BannedFunctionsEditField
            app.BannedFunctionsEditField = uieditfield(app.ProblemSettingsPanel, 'text');
            copyFrom(app.BannedFunctionsEditField, layout.BannedFunctionsEditField, ...
                {'FontName', 'Enable', 'Position'});
            %             app.BannedFunctionsEditField.FontName = 'Consolas';
            %             app.BannedFunctionsEditField.Enable = 'off';
            %             app.BannedFunctionsEditField.Position = [11 38 80 22];
            %             app.BannedFunctionsEditField.Position = layout.BannedFunctionsEditField.Position;
            
            app.FunctionBrowsePanel = uipanel(app.UIFigure);
            copyFrom(app.FunctionBrowsePanel, layout.FunctionBrowsePanel, ...
                {'Title', 'Position'});
            app.FunctionBrowseButton = uibutton(app.FunctionBrowsePanel);
            copyFrom(app.FunctionBrowseButton, layout.FunctionBrowseButton, ...
                {'Text', 'HorizontalAlignment', 'FontSize', 'Position'});
            app.FunctionBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @FunctionBrowseButtonPushed, true);
            
            app.FunctionDriveBrowseButton = uibutton(app.FunctionBrowsePanel);
            copyFrom(app.FunctionDriveBrowseButton, layout.FunctionDriveBrowseButton, ...
                {'Text', 'HorizontalAlignment', 'FontSize', 'Position'});
            app.FunctionDriveBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @FunctionDriveBrowseButtonPushed, true);
            
            app.SaveLocationPanel = uipanel(app.UIFigure);
            copyFrom(app.SaveLocationPanel, layout.SaveLocationPanel, ...
                {'Title', 'Position'});
            app.LocalBrowseButton = uibutton(app.SaveLocationPanel);
            copyFrom(app.LocalBrowseButton, layout.LocalBrowseButton, ...
                {'Text', 'HorizontalAlignment', 'FontSize', 'Position'});
            app.LocalBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @LocalBrowseButtonPushed, true);
            
            app.OutputFolderBrowseButton = uibutton(app.SaveLocationPanel);
            copyFrom(app.OutputFolderBrowseButton, layout.OutputFolderBrowseButton, ...
                {'Text', 'HorizontalAlignment', 'FontSize', 'Position'});
            app.OutputFolderBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @OutputFolderBrowseButtonPushed, true);
            
            % Create LocalOutputLabel
            app.LocalOutputLabel = uilabel(app.UIFigure);
            %             app.LocalOutputLabel.HorizontalAlignment = 'right';
            %             app.LocalOutputLabel.Position = [11 17 93 22];
            %             app.LocalOutputLabel.Text = '? Local Output';
            copyFrom(app.LocalOutputLabel, layout.LocalOutputLabel, ...
                {'HorizontalAlignment', 'Position', 'Text'});
            
            % Create LocalOutputEditField
            app.LocalOutputEditField = uieditfield(app.UIFigure, 'text');
            app.LocalOutputEditField.Editable = 'off';
            %             app.LocalOutputEditField.Position = [119 17 212 22];
            %             app.LocalOutputEditField.Value = 'Not selected';
            copyFrom(app.LocalOutputEditField, layout.LocalOutputEditField, ...
                {'Position', 'Value', 'FontName'});
            
            % Create GoogleDriveLabel
            app.GoogleDriveLabel = uilabel(app.UIFigure);
            %             app.GoogleDriveLabel.HorizontalAlignment = 'right';
            %             app.GoogleDriveLabel.Position = [332 17 95 22];
            %             app.GoogleDriveLabel.Text = '? Google Drive';
            copyFrom(app.GoogleDriveLabel, layout.GoogleDriveLabel, ...
                {'HorizontalAlignment', 'Position', 'Text'});
            
            % Create GoogleDriveEditField
            app.GoogleDriveEditField = uieditfield(app.UIFigure, 'text');
            app.GoogleDriveEditField.Editable = 'off';
            %             app.GoogleDriveEditField.Position = [442 17 139 22];
            %             app.GoogleDriveEditField.Value = 'Not selected';
            copyFrom(app.GoogleDriveEditField, layout.GoogleDriveEditField, ...
                {'Position', 'Value', 'FontName'});
            
            % Clear buttons for local and drive
            app.LocalOutputClearButton = uibutton(app.UIFigure, 'push');
            copyFrom(app.LocalOutputClearButton, layout.LocalOutputClearButton, ...
                {'Position', 'Text'});
            app.LocalOutputClearButton.ButtonPushedFcn = @LocalOutputClearButtonPressed;
            
            app.DriveOutputClearButton = uibutton(app.UIFigure, 'push');
            copyFrom(app.DriveOutputClearButton, layout.DriveOutputClearButton, ...
                {'Position', 'Text'});
            app.DriveOutputClearButton.ButtonPushedFcn = @DriveOutputClearButtonPressed;
            
            function DriveOutputClearButtonPressed(~, ~)
                app.folderId = '';
                app.folderName = '';
            end
            
            function LocalOutputClearButtonPressed(~, ~)
                app.LocalOutputDir = '';
            end

            
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
    
    properties (Access = private)
        PushIndex = 0
    end
end