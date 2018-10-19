classdef Problem
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
    end
end

