classdef SubmissionType
    %% SubmissionType Represent a category of submission
    %
    % This class represents a category of submission, such as 'student',
    % 'submission', or 'resubmission'. A SubmissionType object stores data
    % particular to each submission category, including the test cases
    % themselves, supporting files, and base words.
    %
    % @authors Justin Htay, Daniel Profili, Hannah White
    
    properties
        % The name of the submission type/category
        name char
        
        % The number of test cases this submission type has (3 by default)
        numTestCases = 3
        
        % Array of tabs containing the test case input fields
        testCaseTabs matlab.ui.container.Tab
        
        % Array of input dropdown menus
        inputDropDowns matlab.ui.control.DropDown
        
        % Cell array of output base words
        outputBaseWords cell
        
        % Array of test cases
        testCases TestCase
        
        % Cell array of full paths to supporting files
        supportingFiles cell
        
        % Array of buttons placed on user-added test case tabs
        testCaseRemoveButtons matlab.ui.control.Button
        
        % The "new test case" button object
        testCaseNewTab matlab.ui.container.Tab
    end
    
    properties (Constant, Access = public)
        MIN_NUM_TEST_CASES = 3
    end
    
    methods
        %% Constructor
        %
        % obj = SubmissionType(NAME) Constructs a new SubmissionType object with
        % name NAME and everything else uninitialized, if NAME is among the
        % allowed submission type names. If it is not, a
        % TESTCASE:SubmissionType:ctor:invalidSubmissionType exception is
        % thrown.
        function this = SubmissionType(name)
            this.name = name;
            
            for i = 1:this.MIN_NUM_TEST_CASES
                this.testCases = [this.testCases, TestCase()];
            end
        end
    end
end

