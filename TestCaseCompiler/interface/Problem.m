classdef Problem
    %% PROBLEM Represent a homework problem
    %
    % A Problem contains information common to all test cases - that is,
    % the name of the function, the solution .m path, etc.
    %
    % Only one of these should exist at a time in an instance of the
    % generator UI.
    
    properties
        functionPath char % path to the solution .m file
        functionName char % name of the function WITHOUT .m extension
        numInputs double % result of nargin(functionName)
        numOutputs double % result of nargout(functionName)
        bannedFunctions cell % cell array of banned function names
        isRecursive = false % whether the function is recursive or not
        submissionTypes SubmissionType % vector of submission type objects
    end
    
    properties (Access = private, Constant)
        SUBMISSION_TYPES = {'student', 'submission', 'resubmission'}
    end
    
    methods
        %% Problem Create a new Problem object
        %
        % THIS = Problem(NAME, F, I, O) creates a new Problem object with
        % function name NAME (without the .m extension), absolute path to
        % solution file F, number of inputs I, and number of outputs O.
        function this = Problem(name, funcPath)
            this.functionName = name;
            this.functionPath = funcPath;
            
            this.numInputs = nin;
            this.numOutputs = nout;
            
            % Create the SubmissionType objects to store the test cases
            for ty = this.SUBMISSION_TYPES
                this.submissionTypes = [this.submissionTypes, SubmissionType(ty)];
            end
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

