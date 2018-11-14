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

    % create the student package
    progress.Message = 'Creating student package...';
    try
        package([pwd filesep 'student'], ...
            student.outBase, ...
            student.inputNames, ...
            student.functionPath, ...
            student.inputValues, ...
            student.supportingFiles, ...
            student.numTestCases, ...
            student.isRecursive, ...
            student.bannedFunctions);
    catch e
        uialert(app.UIFigure, e.message, ...
            'Error encountered while creating student package!');
        return;
    end
    progress.Message = 'Verifying student package...';
    % verify the student
    try
        [isCorrect, cases, msg] = verify([pwd filesep solnFunction '.m'], ...
            [pwd filesep 'student']);
    catch e
        isCorrect = false;
        cases = [];
        msg = sprintf('Verification error (%s): "%s"', e.identifier, e.message);
    end
    if ~isCorrect
        if isempty(cases)
            msg = sprintf('Verification failed: %s', msg);
        else
            messages = cellfun(@(x) x.message, msg, 'uni', false);
            messagesStr = strjoin(messages, '\n');
            msg = sprintf('Verification failed on test case(s) %s: %s', ...
                strjoin(arrayfun(@num2str, cases, 'uni', false), ', '), ...
                messagesStr);
        end
        uialert(app.UIFigure, msg, 'Student Verification Failure');
    end
    % create the submission package
    progress.Message = 'Creating submission package...';
    try
        package([pwd filesep 'submission'], ...
            submission.outBase, ...
            submission.inputNames, ...
            submission.functionPath, ...
            submission.inputValues, ...
            submission.supportingFiles, ...
            submission.numTestCases, ...
            submission.isRecursive, ...
            submission.bannedFunctions);
    catch e
        uialert(app.UIFigure, e.message, ...
            'Error encountered while creating submission package!');
        return;
    end
    % verify the submission
    progress.Message = 'Verifying submission package...';
    try
        [isCorrect, cases, msg] = verify([pwd filesep solnFunction '.m'], ...
            [pwd filesep 'submission']);
    catch e
        isCorrect = false;
        cases = [];
        msg = sprintf('Verification error (%s): "%s"', e.identifier, e.message);
    end
    if ~isCorrect
        if isempty(cases)
            msg = sprintf('Verification failed: %s', msg);
        else
            msg = sprintf('Verification failed on test case(s) %s: %s', ...
                strjoin(arrayfun(@num2str, cases, 'uni', false), ', '), ...
                msg);
        end
        uialert(app.UIFigure, msg, 'Submission verification failure!');
    end
    if ~isempty(resub)
        % create the resubmission package
        progress.Message = 'Creating resubmission package...';
        try
            package([pwd filesep 'resub'], ...
                resub.outBase, ...
                resub.inputNames, ...
                resub.functionPath, ...
                resub.inputValues, ...
                resub.supportingFiles, ...
                resub.numTestCases, ...
                resub.isRecursive, ...
                resub.bannedFunctions);
        catch e
            uialert(app.UIFigure, e.message, ...
                'Error encountered while creating submission package!');
            return;
        end
        % verify the resubmission
        progress.Message = 'Verifying resubmission package...';
        try
            [isCorrect, cases, msg] = verify([pwd filesep solnFunction '.m'], ...
                [pwd filesep 'resub']);
        catch e
            isCorrect = false;
            cases = [];
            msg = sprintf('Verification error (%s): "%s"', e.identifier, e.message);
        end
        if ~isCorrect
            if isempty(cases)
                msg = sprintf('Verification failed: %s', msg);
            else
                msg = sprintf('Verification failed on test case(s) %s: %s', ...
                    strjoin(arrayfun(@num2str, cases, 'uni', false), ', '), ...
                    msg);
            end
            uialert(app.UIFigure, msg, 'Resubmission verification failure!');
        end
    end
    
    % upload to google drive
    if app.exportDriveSelected
        token = refresh2access(app.token);
        progress.Message = 'Uploading package to Google Drive...';
        uploadToDrive(pwd, app.folderId, token, app.key, progress);
        progress.close();
    end
    
    % local output
    if app.exportLocalSelected
        progress.Message = sprintf('Saving to %s...', app.LocalOutputDir);
        copyfile([workDir, filesep, solnFunction, filesep, '*'], app.LocalOutputDir, 'f');
    end
end

function cleaner(path, rmPath)
    cd(path);
    rmdir(rmPath, 's');
end