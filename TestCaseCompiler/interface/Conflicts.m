classdef Conflicts < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        ConflictsListBoxLabel  matlab.ui.control.Label
        ConflictsListBox       matlab.ui.control.ListBox
        Title                  matlab.ui.control.Label
        WorkspaceSwitch        matlab.ui.control.Switch
        ConfirmButton          matlab.ui.control.Button
        CancelButton           matlab.ui.control.Button
        VariablePreview        matlab.ui.control.TextArea
    end

    
    properties (Dependent, Access=public)
        IsMain logical;
        VariableNames string;
    end
    
    properties (Access = private)
        isMain logical;
        variableNames string;
        archiveValues cell;
        mainValues cell;
    end
    
    methods
        
        function set.IsMain(app, val)
            % everything that is different will need to be changed
            mainMask = (app.isMain ~= val) & val;
            archMask = (app.isMain ~= val) & ~val;
            app.ConflictsListBox.Items(mainMask) = ...
                compose('%s (%s)', app.variableNames(mainMask)', 'Main');
            app.ConflictsListBox.Items(archMask) = ...
                compose('%s (%s)', app.variableNames(archMask)', 'Archive');
            app.isMain = val;
        end
    
        function tf = get.IsMain(app)
            tf = app.isMain;
        end
    
        function set.VariableNames(app, val)
            app.variableNames = val;
        end
    
        function vars = get.VariableNames(app)
            vars = app.variableNames;
        end
    end
    
    methods (Static, Access = private)
        function [str] = toString(in)
            if islogical(in)
                if in
                    str = 'true';
                else
                    str = 'false';
                end
            elseif ischar(in) && size(in, 1) == 1
                str = ['''', in, ''''];
            else
               str = rptgen.toString(in);

            end
        end
    end

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, vars)
            varNames = fieldnames(vars)';
            % Keep in a cell array so we can index correctly
            app.archiveValues = cell(1, numel(varNames));
            app.mainValues = cell(1, numel(varNames));
            for v = 1:numel(varNames)
                app.archiveValues{v} = vars.(varNames{v});
                app.mainValues{v} = evalin('base', varNames{v});
            end
            % 
            % default to main.
            % ItemsData will just be the varNames;
            % Keep separate array of tf values (t is in main)
            app.ConflictsListBox.Items = compose('%s (%s)', string(varNames)', 'Main');
            app.ConflictsListBox.ItemsData = 1:numel(varNames);
            app.VariableNames = string(varNames);
            app.isMain = true(size(varNames));
            app.WorkspaceSwitch.Enable = false;
        end

        % Value changed function: ConflictsListBox
        function ConflictsListBoxValueChanged(app, ~)
            value = app.ConflictsListBox.Value;
            % if all the same, then good to go - set switch value accordingly
            if iscell(value)
                % none selected; die
                app.WorkspaceSwitch.Enable = false;
                app.VariablePreview.Value = '';
                return;
            elseif all(app.IsMain(value))
                app.WorkspaceSwitch.Value = 'Main';
            elseif all(~app.IsMain(value))
                app.WorkspaceSwitch.Value = 'Archive';
            else
                app.WorkspaceSwitch.Value = 'Main';
            end
            
            % if a single selection, show preview
            if isscalar(value)
                if strcmp(app.WorkspaceSwitch.Value, 'Main')
                    % show main val
                    app.VariablePreview.Value = Conflicts.toString(app.mainValues{value});
                else
                    app.VariablePreview.Value = Conflicts.toString(app.archiveValues{value});
                end
            else
                app.VariablePreview.Value = '';
            end
            app.WorkspaceSwitch.Enable = true;
        end

        % Value changed function: WorkspaceSwitch
        function WorkspaceSwitchValueChanged(app, ~)
            value = app.WorkspaceSwitch.Value;
            if ~iscell(app.ConflictsListBox.Value)
                app.IsMain(app.ConflictsListBox.Value) = strcmpi(value, 'Main');
            end
            if isscalar(app.ConflictsListBox.Value)
                if strcmp(app.WorkspaceSwitch.Value, 'Main')
                    % show main val
                    app.VariablePreview.Value = ...
                        Conflicts.toString(app.mainValues{app.ConflictsListBox.Value});
                else
                    app.VariablePreview.Value = ...
                        Conflicts.toString(app.archiveValues{app.ConflictsListBox.Value});
                end
            end
        end

        % Button pushed function: ConfirmButton
        function ConfirmButtonPushed(app, ~)
            % if ~all, then at least one variable is going to die. Warn.
            if ~all(app.IsMain)
                % warn
                choice = uiconfirm(app.UIFigure, ...
                    'You''ve chosen to use at least one archive variable - that means the variable in the main workspace will be overwritten. Are you sure you''d like to continue?', ...
                    'Conflict Management', ...
                    'Options', {'No, let me think', 'Yes, I am sure'}, ...
                    'CancelOption', 'No, let me think', ...
                    'DefaultOption', 'No, let me think', ...
                    'Icon', 'warning');
                if strcmp(choice, 'No, let me think')
                    return;
                end
            end
            uiresume(app.UIFigure);
        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, ~)
            close(app.UIFigure);
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 544 359];
            app.UIFigure.Name = 'Conflict Management';

            % Create ConflictsListBoxLabel
            app.ConflictsListBoxLabel = uilabel(app.UIFigure);
            app.ConflictsListBoxLabel.HorizontalAlignment = 'right';
            app.ConflictsListBoxLabel.FontSize = 15;
            app.ConflictsListBoxLabel.Position = [96 307 65 22];
            app.ConflictsListBoxLabel.Text = 'Conflicts';

            % Create ConflictsListBox
            app.ConflictsListBox = uilistbox(app.UIFigure);
            app.ConflictsListBox.Items = {};
            app.ConflictsListBox.Multiselect = 'on';
            app.ConflictsListBox.ValueChangedFcn = createCallbackFcn(app, @ConflictsListBoxValueChanged, true);
            app.ConflictsListBox.FontSize = 15;
            app.ConflictsListBox.Position = [18 107 220 201];
            app.ConflictsListBox.Value = {};

            % Create Title
            app.Title = uilabel(app.UIFigure);
            app.Title.FontSize = 20;
            app.Title.Position = [6 334 533 26];
            app.Title.Text = 'For each variable, please choose which workspace to use';

            % Create WorkspaceSwitch
            app.WorkspaceSwitch = uiswitch(app.UIFigure, 'slider');
            app.WorkspaceSwitch.Items = {'Main', 'Archive'};
            app.WorkspaceSwitch.ValueChangedFcn = createCallbackFcn(app, @WorkspaceSwitchValueChanged, true);
            app.WorkspaceSwitch.FontSize = 20;
            app.WorkspaceSwitch.Position = [321 300 45 20];
            app.WorkspaceSwitch.Value = 'Main';

            % Create ConfirmButton
            app.ConfirmButton = uibutton(app.UIFigure, 'push');
            app.ConfirmButton.ButtonPushedFcn = createCallbackFcn(app, @ConfirmButtonPushed, true);
            app.ConfirmButton.BackgroundColor = [0.4706 0.6706 0.1882];
            app.ConfirmButton.FontSize = 20;
            app.ConfirmButton.FontWeight = 'bold';
            app.ConfirmButton.FontColor = [1 1 1];
            app.ConfirmButton.Position = [284 31 255 49];
            app.ConfirmButton.Text = 'Confirm';

            % Create CancelButton
            app.CancelButton = uibutton(app.UIFigure, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.BackgroundColor = [0.6392 0.0784 0.1804];
            app.CancelButton.FontSize = 20;
            app.CancelButton.FontWeight = 'bold';
            app.CancelButton.FontColor = [1 1 1];
            app.CancelButton.Position = [6 31 255 49];
            app.CancelButton.Text = 'Cancel';
            
            % Create VariablePreview
            app.VariablePreview = uitextarea(app.UIFigure);
            app.VariablePreview.Position = [273 106 250 190];
            app.VariablePreview.Editable = true;
        end
    end

    methods (Access = public)

        % Construct app
        function app = Conflicts(varargin)

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

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