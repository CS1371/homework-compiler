classdef Problem < handle
    %% PROBLEM Represent a homework problem
    %
    % A Problem contains information common to all test cases - that is,
    % the name of the function, the solution .m path, etc.
    %
    % Only one of these should exist at a time in an instance of the
    % generator UI.
    
    properties (SetAccess = private)
        functionPath char % path to the solution .m file
        functionName char % name of the function WITHOUT .m extension
        numInputs double % result of nargin(functionName)
        numOutputs double % result of nargout(functionName)
        submissionTypes SubmissionType % vector of submission type objects
    end
    
    properties
        bannedFunctions cell % cell array of banned function names
        isRecursive = false % whether the function is recursive or not
    end
    
    properties (Access = private, Constant)
        SUBMISSION_TYPES = {'student', 'submission', 'resubmission'}
    end
    
    methods
        %% Problem Create a new Problem object
        %
        % THIS = Problem(NAME, F) creates a new Problem object with
        % function name NAME (without the .m extension), absolute path to
        % solution file F.
        function this = Problem(name, funcPath)
            this.functionName = name;
            this.functionPath = funcPath;
            
            % get nargin/nargout
            origDir = cd(fileparts(funcPath));
            
            this.numInputs = nargin(path);
            this.numOutputs = nargout(path);
            cd(origDir);
            
            % Create the SubmissionType objects to store the test cases
            for ty = this.SUBMISSION_TYPES
                this.submissionTypes = [this.submissionTypes, SubmissionType(ty)];
            end
        end
        
        %% getSubType Gets a submission type object by name
        %
        % Returns the SubmissionType object corresponding to a particular
        % (case-insensitive) name.
        %
        % Used to nicely emulate the old janky way of doing stuff with
        % MATLAB's dynamic determination of struct field names, but works
        % slightly better because of slightly more error checking.
        function typeObj = getSubType(this, name)
            typeObj = [];
            for i = 1:length(this.submissionTypes)
                if strcmpi(this.submissionTypes(i).Name, name)
                    typeObj = this.submissionTypes(i);
                end
            end
            
            % complain if not valid
            if isempty(typeObj)
                throw(MException('TESTCASE:Problem:getSubType:invalidSubmissionType', ...
                    '%s is not a valid submission type', name));
            end
        end
    end
end

