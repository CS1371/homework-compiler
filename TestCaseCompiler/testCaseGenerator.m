%% testCaseGenerator: Main entry point for the Test Case Generator
%
% testCaseGenerator is the main entry point for the generator. It controls
% the logic for packaging, verifying, and deploying test cases to Google
% Drive.
%
% testCaseGenerator(T) will use testCaseGenerator app T to work.
%
%%% Remarks
%
% This takes the options specified in T to create the packages, verify
% them, and deploy them to Google Drive. The output package is strongly
% linked to the input of the Homework Generator.
%
% Package:
%   outBase
%   inputNames
%   functionPath
%   inputValues
%   supportingFiles
%   bannedFunctions
%   isRecursive
%
% (c) 2018 CS1371 (J. Htay, D. Profili, A. Rao, H. White)
function testCaseGenerator(app)
    % get the three packages
    progress = ProgressBar(app.UIFigure, ...
        'Cancelable', 'on', 'Indeterminate', 'on', ...
        'Message', 'Preparing to create archive', ...
        'ShowPercentage', 'on', 'Value', 0, 'Title', 'Packaging Progress');
%     progress = ProgressBar(app.UIFigure, 'Cancelable', true, 'Indeterminate', ...
%         true, 'Message', 'Preparing to create archive', ...
%         'Progress', 0, 'Title', 'Packaging Progress');
%     student = app.getPackage('Student');
%     submission = app.getPackage('Submission');
%     resub = app.getPackage('Resubmission');
    pkg = app.getPackage();
    student = pkg(1);
    submission = pkg(2);
    resub = pkg(3);

    workDir = tempname;
    mkdir(workDir);
    initialDir = pwd;
    clean = onCleanup(@()(cleaner(initialDir, workDir)));
    cd(workDir);
    
    % copy soln function; remove _soln if found
    progress.Message = 'Parsing solution file...';
    oldSolnPath = student.functionPath;
    [solnPath, solnFunction, ~] = fileparts(student.functionPath);
    solnFunction = strrep(solnFunction, '_soln', '');
    student.functionPath = [solnPath filesep solnFunction '.m'];
    submission.functionPath  = [solnPath filesep solnFunction '.m'];
    if ~isempty(resub)
        resub.functionPath = [solnPath filesep solnFunction '.m'];
    end
    
    % rename
    if ~strcmp(oldSolnPath, student.functionPath)
        copyfile(oldSolnPath, student.functionPath);
    end
    
    % rename file
%     movefile(oldSolnPath, student.functionPath, 'f');
    
    mkdir(solnFunction);
    cd(solnFunction);
    
%     copyfile(student.functionPath, [pwd filesep solnFunction '.m']);
    copyfile(oldSolnPath, [pwd filesep solnFunction '.m']);
    function createPackage(name, st)
        % create the student package
        progress.Message = ['Creating ' name ' package...'];
        try
            package([pwd filesep name], ...
                st.outBase, ...
                st.inputNames, ...
                st.functionPath, ...
                st.inputValues, ...
                st.supportingFiles, ...
                st.numTestCases, ...
                st.isRecursive, ...
                st.bannedFunctions);
        catch e
            uialert(app.UIFigure, e.message, ...
                ['Error encountered while creating ' name ' package!']);
            throw(MException('TESTCASE:testCaseGenerator:genericError', ...
                sprintf('Error creating %s package', name)));
        end
    end

    function verifyPackage(name)
        progress.Message = ['Verifying ' name ' package...'];
        % verify the student
        try
            [isCorrect, cases, msg] = verify([pwd filesep solnFunction '.m'], ...
                [pwd filesep name]);
        catch e
            isCorrect = false;
            cases = [];
            msg = sprintf('Verification error (%s): "%s"', e.identifier, e.message);
        end
        if ~isCorrect
            if isempty(cases)
                msg = sprintf('Verification failed: %s', msg);
            else
                msg = failureMsg(msg, cases);
            end
            name(1) = upper(name(1));
            uialert(app.UIFigure, msg, [name ' verification failed!']);
            throw(MException('TESTCASE:testCaseGenerator:genericError', ...
                sprintf('Error creating %s package', name)));

        end
    end

    try
        createPackage('student', student);
        verifyPackage('student');

        createPackage('submission', submission);
        verifyPackage('submission');

        if ~isempty(resub)
            createPackage('resub', resub);
            verifyPackage('resub');
        end
    catch
        return;
    end
    
    % upload to google drive
    if ~isempty(app.folderId)
        token = refresh2access(app.token, app.clientId, app.clientSecret);
        progress.Message = 'Uploading package to Google Drive...';
        uploadToDrive(pwd, app.folderId, token, app.clientKey, progress);
        progress.close();
    end
    
    % local output
    if ~isempty(app.LocalOutputDir)
        progress.Message = sprintf('Saving to %s...', app.LocalOutputDir);
        % watch out for this---not sure if it'll cause problems if the file
        % exists and isn't the same
%         delete(fullfile(app.LocalOutputDir, '*'));
        copyfile([workDir, filesep, solnFunction, filesep, '*'], app.LocalOutputDir, 'f');
    end
    
end

function msg = failureMsg(exceptions, nums)
messages = cellfun(@(x) x.message, exceptions, 'uni', false);
messagesStr = strjoin(messages, '\n');

msg = sprintf('Verification failed on test case(s) %s: %s', ...
    strjoin(arrayfun(@num2str, nums, 'uni', false), ', '), ...
    messagesStr);
end

function cleaner(path, rmPath)
    cd(path);
    rmdir(rmPath, 's');
end