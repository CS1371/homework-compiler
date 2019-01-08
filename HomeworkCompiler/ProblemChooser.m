classdef ProblemChooser < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        Confirm                        matlab.ui.control.Button
        ProblemOrderPanel              matlab.ui.container.Panel
        OrderLabel                     matlab.ui.control.Label
        Problems                       matlab.ui.control.ListBox
        Up                             matlab.ui.control.Button
        Down                           matlab.ui.control.Button
        AssignmentInformationPanel     matlab.ui.container.Panel
        AssignmentTopicEditFieldLabel  matlab.ui.control.Label
        Topic                          matlab.ui.control.EditField
        PointDistributionPanel         matlab.ui.container.Panel
        Cancel                         matlab.ui.control.Button
    end


    properties (Access = public)
        Checks % Description
        Points
        Names
    end


    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, problemNames)
            app.Problems.Items = problemNames;
            app.Problems.ItemsData = 1:numel(problemNames);
            y = 230;
            problemNames = problemNames(end:-1:1);
            dist = floor(100 / numel(problemNames));
            extra = mod(100, numel(problemNames));
            % for each problem, create check box and corresponding edit field
            for p = numel(problemNames):-1:1
                if p == 1
                    val = dist + extra;
                else
                    val = dist;
                end
                % Create Name, Check box, Point box
                names(p) = uilabel(app.UIFigure, 'FontName', 'Courier New', ...
                    'Position', [18 y 125 25], 'Text', problemNames{p}, ...
                    'Parent', app.PointDistributionPanel);
                checks(p) = uicheckbox(app.UIFigure, ...
                    'Position', [150 y 100 25], 'Value', false, ...
                    'Text', 'Extra Credit?', 'Parent', app.PointDistributionPanel);
                points(p) = uieditfield(app.UIFigure, 'numeric', ...
                    'FontName', 'Courier New', 'Position', [300 y 81 25], ...
                    'Parent', app.PointDistributionPanel, 'Visible', 'on', ...
                    'LowerLimitInclusive', 'on', 'Limits', [0 Inf], ...
                    'Value', val);
                y = y - 30;
            end
            names = names(end:-1:1);
            checks = checks(end:-1:1);
            points = points(end:-1:1);
            app.Names = names;
            app.Checks = checks;
            app.Points = points;
            
        end

        % Button pushed function: Up
        function UpPushed(app, ~)
            ind = app.Problems.Value;
            names = app.Problems.Items;
            if ind == 1
                return;
            else
                % swap one above with this one
                % names{ind} = names{ind-1}, vv
                tmp = names{ind};
                names{ind} = names{ind-1};
                names{ind-1} = tmp;
                
                tmp = app.Names(ind);
                app.Names(ind) = app.Names(ind-1);
                app.Names(ind-1) = tmp;
                
                tmpPosn = app.Names(ind).Position;
                app.Names(ind).Position = app.Names(ind-1).Position;
                app.Names(ind-1).Position = tmpPosn;
                
                
                tmp = app.Checks(ind);
                app.Checks(ind) = app.Checks(ind-1);
                app.Checks(ind-1) = tmp;
                
                tmpPosn = app.Checks(ind).Position;
                app.Checks(ind).Position = app.Checks(ind-1).Position;
                app.Checks(ind-1).Position = tmpPosn;
                
                tmp = app.Points(ind);
                app.Points(ind) = app.Points(ind-1);
                app.Points(ind-1) = tmp;
                
                tmpPosn = app.Points(ind).Position;
                app.Points(ind).Position = app.Points(ind-1).Position;
                app.Points(ind-1).Position = tmpPosn;
            end
            app.Problems.Items = names;
            app.Problems.Value = ind - 1;
        end

        % Button pushed function: Down
        function DownPushed(app, ~)
            ind = app.Problems.Value;
            names = app.Problems.Items;
            if ind == numel(names)
                return;
            else
                % swap one above with this one
                % names{ind} = names{ind-1}, vv
                tmp = names{ind};
                names{ind} = names{ind+1};
                names{ind+1} = tmp;
                
                tmp = app.Names(ind);
                app.Names(ind) = app.Names(ind+1);
                app.Names(ind+1) = tmp;
                
                tmpPosn = app.Names(ind).Position;
                app.Names(ind).Position = app.Names(ind+1).Position;
                app.Names(ind+1).Position = tmpPosn;
                
                
                tmp = app.Checks(ind);
                app.Checks(ind) = app.Checks(ind+1);
                app.Checks(ind+1) = tmp;
                
                tmpPosn = app.Checks(ind).Position;
                app.Checks(ind).Position = app.Checks(ind+1).Position;
                app.Checks(ind+1).Position = tmpPosn;
                app.Checks(ind).ValueChangedFcn = {@ProblemChooser.func, app, ind};
                app.Checks(ind+1).ValueChangedFcn = {@ProblemChooser.func, app, ind+1};
                
                tmp = app.Points(ind);
                app.Points(ind) = app.Points(ind+1);
                app.Points(ind+1) = tmp;
                
                tmpPosn = app.Points(ind).Position;
                app.Points(ind).Position = app.Points(ind+1).Position;
                app.Points(ind+1).Position = tmpPosn;
            end
            app.Problems.Items = names;
            app.Problems.Value = ind + 1;
        end

        % Button pushed function: Confirm
        function ConfirmPushed(app, ~)
            if isempty(app.Topic.Value)
                app.Topic.BackgroundColor = [.95 .75 .75];
                return;
            end
            
            % Check points
            % for each one, look at point value, if not extra credit. It
            % should add up to exactly 100%.
            
            inds = [app.Checks.Value];
            pts = app.Points(~inds);
            if sum([pts.Value]) ~= 100
                uialert(app.UIFigure, ...
                    sprintf('Regular (not EC) points should sum to 100 - currently, they sum to %d', ...
                    sum([pts.Value])), ...
                    'Homework Compiler');
                return;
            end
            uiresume(app.UIFigure);
        end

        % Button pushed function: Cancel
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
            app.UIFigure.Position = [100 100 760 400];
            app.UIFigure.Name = 'Problem Chooser';

            % Create Confirm
            app.Confirm = uibutton(app.UIFigure, 'push');
            app.Confirm.ButtonPushedFcn = createCallbackFcn(app, @ConfirmPushed, true);
            app.Confirm.BackgroundColor = [0.4706 0.6706 0.1882];
            app.Confirm.FontSize = 24;
            app.Confirm.FontColor = [1 1 1];
            app.Confirm.Position = [572 17 175 66];
            app.Confirm.Text = 'Confirm';

            % Create ProblemOrderPanel
            app.ProblemOrderPanel = uipanel(app.UIFigure);
            app.ProblemOrderPanel.Title = 'Problem Order';
            app.ProblemOrderPanel.FontSize = 20;
            app.ProblemOrderPanel.Position = [1 98 348 303];

            % Create OrderLabel
            app.OrderLabel = uilabel(app.ProblemOrderPanel);
            app.OrderLabel.HorizontalAlignment = 'right';
            app.OrderLabel.FontSize = 22;
            app.OrderLabel.Position = [97 240 61 29];
            app.OrderLabel.Text = 'Order';

            % Create Problems
            app.Problems = uilistbox(app.ProblemOrderPanel);
            app.Problems.Items = {};
            app.Problems.FontName = 'Courier New';
            app.Problems.Position = [32 15 191 226];
            app.Problems.Value = {};

            % Create Up
            app.Up = uibutton(app.ProblemOrderPanel, 'push');
            app.Up.ButtonPushedFcn = createCallbackFcn(app, @UpPushed, true);
            app.Up.Position = [238 206 100 22];
            app.Up.Text = 'Move Up';

            % Create Down
            app.Down = uibutton(app.ProblemOrderPanel, 'push');
            app.Down.ButtonPushedFcn = createCallbackFcn(app, @DownPushed, true);
            app.Down.Position = [238 155 100 22];
            app.Down.Text = 'Move Down';

            % Create AssignmentInformationPanel
            app.AssignmentInformationPanel = uipanel(app.UIFigure);
            app.AssignmentInformationPanel.Title = 'Assignment Information';
            app.AssignmentInformationPanel.FontSize = 20;
            app.AssignmentInformationPanel.Position = [1 1 422 98];

            % Create AssignmentTopicEditFieldLabel
            app.AssignmentTopicEditFieldLabel = uilabel(app.AssignmentInformationPanel);
            app.AssignmentTopicEditFieldLabel.HorizontalAlignment = 'right';
            app.AssignmentTopicEditFieldLabel.Position = [20 29 101 22];
            app.AssignmentTopicEditFieldLabel.Text = 'Assignment Topic';

            % Create Topic
            app.Topic = uieditfield(app.AssignmentInformationPanel, 'text');
            app.Topic.Position = [136 29 251 22];

            % Create PointDistributionPanel
            app.PointDistributionPanel = uipanel(app.UIFigure);
            app.PointDistributionPanel.Title = 'Point Distribution';
            app.PointDistributionPanel.FontSize = 20;
            app.PointDistributionPanel.Position = [348 98 413 303];

            % Create Cance
            app.Cancel = uibutton(app.UIFigure, 'push');
            app.Cancel.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.Cancel.BackgroundColor = [0.6392 0.0784 0.1804];
            app.Cancel.FontSize = 24;
            app.Cancel.FontColor = [1 1 1];
            app.Cancel.Position = [431 17 130 66];
            app.Cancel.Text = 'Cancel';
        end
    end

    methods (Access = public)

        % Construct app
        function app = ProblemChooser(varargin)

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