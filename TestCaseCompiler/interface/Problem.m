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
    
    properties (Access = private, Constant)
        SUBMISSION_TYPES = {'Student', 'Submission', 'Resubmission'}
    end
    
    methods
        %% Problem Create a new Problem object
        %
        % THIS = Problem(NAME, F) creates a new Problem object with
        % function name NAME (without the .m extension), absolute path to
        % solution file F.
        function this = Problem(funcPath)
            
            % get nargin/nargout
            origDir = cd(fileparts(funcPath));
            
            this.NumInputs = nargin(funcPath);
            this.NumOutputs = nargout(funcPath);
            cd(origDir);
            
            [~, this.FunctionName] = fileparts(funcPath);
            this.FunctionPath = funcPath;

            
%             % Create the SubmissionType objects to store the test cases
%             for ty = this.SUBMISSION_TYPES
%                 this.SubmissionTypes = [this.SubmissionTypes, SubmissionType(ty, this)];
%             end
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
            for sub = this.SubmissionTypes
                sub.refreshInputsList();
            end
        end
    end
end

