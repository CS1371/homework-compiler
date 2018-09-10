classdef SubmissionType
    %% SUBMISSIONTYPE Represents a submission type
    % 
    % This class is used to group together properties that are common to a
    % 'submission type' (i.e. student test, submission, or resubmission).
    
    properties
        Name char
    end
    
    properties (Constant, Access = private)
        NUM_TYPES = 3
        TYPES = {'student', 'submission', 'resubmission'}
    end
    
    methods (Access = private)
        
    end
    
    methods
        function this = SubmissionType(name)
            %% SUBMISSIONTYPE Construct an instance of this class
            %   
            % Constructs a new submission type. The number of instances
            % that are allowed at any one time is the number of submission
            % types. This is done to prevent accidental creation of too
            % many instances.
            
            % The number of instances that have been created
            persistent numInstances;
            
            % Vector of submission type objects that have been created
            % already
            persistent instances;
            
            if isempty(instances)
                % if no instances yet, add it normally
                this.Name = name;
                instances = this;
                numInstances = 1;
            elseif numInstances < this.NUM_TYPES
                if any(strcmp(TYPES, name))
                    % if instance already created, return that one
                    loc = strcmp({instances.Name}, name);
                    this = instances(loc);
                else
                    % if it doesn't exist, add it
                    this.name = name;
                    instances = [instances, this];
                    numInstances = numInstances + 1;
                end
            else
                % numInstances >= NUM_TYPES, so find the right one and
                % return
                loc = strcmp({instances.Name}, name);
                this = instances(loc);
            end
            
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

