classdef ProgressBar < handle
    % PROGRESSBAR Represents a progress bar dialog
    %
    %
    %
    %
    
    properties
        Indeterminate
        Message
        Title
        Value
        Cancelable
        WindowStyle
        ShowPercentage
    end
    
    properties (Access = private)
        is2018a
        backingObject
        Parent
        isInitialized = false
    end
    
    methods
        function this = ProgressBar(parent, varargin)
            %% Constructor
            %
            % Creates a ProgressBar object.
            %
            % this = ProgressBar(PARENT) creates an empty ProgressBar object
            % with parent object PARENT.
            
            % Validate inputs
            toggleValidateFcn = @(x)(islogical(x) || any(validatestring(x, {'on', 'off'})));
            p = inputParser();
            p.addRequired('Parent', @(x)(isa(x, 'matlab.ui.Figure')));
            p.addParameter('Title', 'Progress Bar', @ischar);
            p.addParameter('Indeterminate', false, toggleValidateFcn);
            p.addParameter('Message', '', @ischar);
            p.addParameter('Value', 0, @(x)(x >= 0 && x <= 1));
            p.addParameter('Cancelable', false, toggleValidateFcn);
            p.addParameter('WindowStyle', 'normal', @(x)(any(validatestring(x, {'normal', ...
                'modal', 'docked'}))));
            p.addParameter('ShowPercentage', false, toggleValidateFcn);
            parse(p, parent, varargin{:});
            
            % Add fields
            this.is2018a = datenum(version('-date')) >= datenum('February 23, 2018');
%             setProperties(this, nargin, varargin{:});
            this.Parent = p.Results.Parent;
            this.Title = p.Results.Title;
            this.Indeterminate = p.Results.Indeterminate;
            this.Message = p.Results.Message;
            this.Value = p.Results.Value;
            this.Cancelable = p.Results.Cancelable;
            this.WindowStyle = p.Results.WindowStyle;
            this.ShowPercentage = p.Results.ShowPercentage;
            
            this.isInitialized = true;
            % show
            this.show();
            
        end
        
        function show(this)
            %% SHOW Shows the progress bar
            %
            % Actually displays the progress bar object.
            %
            %%% Remarks
            %
            % What is actually shown depends on the MATLAB version running. If
            % the version is 2018a or greater, the progress bar shown will be a
            % uiprogressdlg(). Otherwise, it will be a waitbar().
            if ~isempty(this.backingObject)
                this.close();
            end
            if this.is2018a
                if strcmp(this.Indeterminate, 'on') || isequal(this.Indeterminate, true)
                    this.backingObject = uiprogressdlg(this.Parent, 'Title', this.Title, ...
                        'Message', this.Message, 'Indeterminate', this.Indeterminate, ...
                        'ShowPercentage', this.ShowPercentage);
                else
                    this.backingObject = uiprogressdlg(this.Parent, 'Title', this.Title, ...
                        'Message', this.Message, 'Value', this.Value, ...
                        'ShowPercentage', this.ShowPercentage);
                end
            else
                this.backingObject = waitbar(this.Value, this.Message, ...
                    'Name', this.Title, 'WindowStyle', this.WindowStyle);
            end
            
        end
        
        function close(this)
            %% CLOSE Close the progress bar
            %
            % Closes the progress bar window.
            %
            %%% Remarks
            %
            % close() does not delete the object. The window can be shown again
            % with show().
            if isempty(this.backingObject)
               throw(MException('TESTCASE:ProgressBar:noObject', ...
                   'There is no progress bar to close!')); 
            end

            close(this.backingObject);
            
        end
        
        function set.Value(this, prog)
            this.Value = prog;
            if this.isInitialized
                this.Indeterminate = false;
                if this.is2018a
                    this.backingObject.Value = prog;
                else
                    waitbar(prog);
                end
                this.show();
            end
        end
        
        function set.Title(this, title)
            this.Title = title;
            if this.isInitialized
                this.show();
            end
        end
        
        function set.Message(this, msg)
            this.Message = msg;
            if this.isInitialized
                this.show();
            end
        end
        
        function set.Indeterminate(this, ind)
           this.Indeterminate = ind;
           if this.isInitialized
               this.show();
           end
        end
    end
end

