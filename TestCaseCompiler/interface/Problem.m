classdef Problem < handle
    %% PROBLEM Represent a homework problem
    %
    % A Problem contains information common to all test cases - that is,
    % the name of the function, the solution .m path, etc.
    %
    % Only one of these should exist at a time in an instance of the
    % generator UI.
    %
    % (c) 2018 CS1371 (J. Htay, D. Profili, A. Rao, H. White)

    
    properties (SetAccess = private)
        FunctionPath char % path to the solution .m file
        FunctionName char % name of the function WITHOUT .m extension
        NumInputs double % result of nargin(functionName)
        NumOutputs double % result of nargout(functionName)
        SubmissionTypes SubmissionType % vector of submission type objects
    end
    
    properties
        BannedFunctions cell % cell array of banned function names
        IsRecursive = false % whether the function is recursive or not
    end
    
    properties (Hidden)
       SelectedSubmission char 
    end
    
    properties (Access = private, Constant)
        SUBMISSION_TYPES = {'Student', 'Submission', 'Resubmission'}
    end
    
    methods
        %% Problem Create a new Problem object
        %
        % THIS = Problem(PATH, TABGROUP) creates a new Problem object with
        % path to solution function NAME and uitabgroup object TABGROUP.
        %
        % THIS = Problem(PKGPATH, TABGROUP, 'load') loads a Problem object
        % from package path PKGPATH.
        function this = Problem(funcPath, rubricTabGroup, varargin)
            if isempty(varargin)

                % get nargin/nargout
                origDir = cd(fileparts(funcPath));

                this.NumInputs = nargin(funcPath);
                this.NumOutputs = nargout(funcPath);
                cd(origDir);

                [~, this.FunctionName] = fileparts(funcPath);
                this.FunctionPath = funcPath;

                % add the submission type objects
                this.addSubmissionType('Student', rubricTabGroup);
                this.addSubmissionType('Submission', rubricTabGroup);
                this.addSubmissionType('Resubmission', rubricTabGroup);
                
                this.SelectedSubmission = 'Student';
                
                % add verification callback for changing submissions
                rubricTabGroup.SelectionChangedFcn = @(a, ev) tabGroupChangedFcn(ev.Source.SelectedTab.Title);
                

                
    %             % Create the SubmissionType objects to store the test cases
    %             for ty = this.SUBMISSION_TYPES
    %                 this.SubmissionTypes = [this.SubmissionTypes, SubmissionType(ty, this)];
    %             end
            elseif length(varargin) == 1 && strcmpi(varargin{1}, 'load')
                % load from a package
                this.loadFromPackage(funcPath, tabGroup);
            else
               throw(MException('TESTCASE:Problem:ctor:illegalArgumentException', ...
                   'The only extra input allowed is ''load'' to load from a package.'));
            end
            
            function tabGroupChangedFcn(newTabTitle)
                currentSubObj = [];
                for st = this.SubmissionTypes
                    cleanTitle = strrep(st.Name, '!! ', '');
                    if isequal(cleanTitle, this.SelectedSubmission)
                        currentSubObj = st;
                    end
                end
                
                title = currentSubObj.Tab.Title;
                if currentSubObj.verifyAllTestCases()
                    % success
                    currentSubObj.Tab.Title = strrep(title, '!! ', '');
                else
                    % fail
                    if ~contains(title, '!!')
                        currentSubObj.Tab.Title = ['!! ', title];
                    end
                end
                
                this.SelectedSubmission = strrep(newTabTitle, '!! ', '');
                
            end
        end
        
        %% loadFromPackage Loads a Problem object from an exported package
        %
        % Loads and verifies the structure of the package given by pkgPath.
        %
        function loadFromPackage(this, pkgPath, tabGroup, app)
            % look for the solution file
            origDir = cd(pkgPath);
            mFiles = dir('*.m');
            if length(mFiles) ~= 1
                throw(MException('TESTCASE:Problem:loadFromPackage:invalidPackage', ...
                    'More than one .m file found in the package directory. Cannot identify solution.'));
            end
            
            
            this.FunctionPath = fullfile(mFiles.folder, mFiles.name);
            this.NumInputs = nargin(this.FunctionPath);
            this.NumOutputs = nargout(this.FunctionPath);  
                        
            % create the submission type tabs
%             this.addSubmissionType('Student', tabGroup);
%             this.addSubmissionType('Submission', tabGroup);
%             this.addSubmissionType('Resubmission', tabGroup);
            
            % autofill with the stuff
            included = dir();
            included = included([included.isdir]);
            included(strcmp({included.name}, '.') | strcmp({included.name}, '..')) = [];
            for ind = 1:length(included)
                d = included(ind);
                switch d.name
                    case 'student'
                        subType = 'Student';
                    case 'submission'
                        subType = 'Submission';
                    case 'resub'
                        subType = 'Resubmission';
                end
                
                subTypeObj = this.getSubType(subType);
                subPath = fullfile(d.folder, d.name);
                homeDir = cd(subPath);
                % delete old tabs
                delete(subTypeObj.Tab);
                
                try
                    infoSt = jsondecode(fileread([d.name, '.json']));
                    this.IsRecursive = infoSt.isRecursive;
                    app.RecursiveCheckBox.Value = infoSt.isRecursive;
                    this.BannedFunctions = infoSt.banned;
                    app.BannedFunctionsListBox.Items = infoSt.banned;
                    subTypeObj.loadFromPackage(infoSt, tabGroup);
                catch ME
                    throw(MException('TESTCASE:Problem:loadFromPackage:invalidJson', ...
                        sprintf('Submission type ''%s'' has an invalid json structure.', ...
                        d.name)));
                end

                cd(homeDir);
            end
            
            
            
            cd(origDir);
        end
        
        %% addSubmissionType Add a submission type to this problem
        %
        function addSubmissionType(this, name, parentTabGroup)
            this.SubmissionTypes = [this.SubmissionTypes, SubmissionType(name, this, parentTabGroup)];
        end
        
        
        %% GetSubType Gets a submission type object by name
        %
        % Returns the SubmissionType object corresponding to a particular
        % (case-insensitive) name.
        %
        % Used to nicely emulate the old janky way of doing stuff with
        % MATLAB's dynamic determination of struct field names, but works
        % slightly better because of slightly more error checking.
        function typeObj = getSubType(this, name)
            typeObj = [];
            name = lower(name);
            for i = 1:length(this.SubmissionTypes)
                if strcmpi(this.SubmissionTypes(i).Name, name)
                    typeObj = this.SubmissionTypes(i);
                end
            end
            
            % complain if not valid
            if isempty(typeObj)
                throw(MException('TESTCASE:Problem:getSubType:invalidSubmissionType', ...
                    '%s is not a valid submission type', name));
            end
        end
        
        %% refreshInputsFromWorkspace
        %
        % Called when new inputs are added
        function refreshInputsFromWorkspace(this)
%             disp('DEBUG: Refreshing inputs');
            for sub = this.SubmissionTypes
                sub.refreshInputsList();
            end
        end
    end
end

