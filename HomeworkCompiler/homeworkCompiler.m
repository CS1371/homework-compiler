%% homeworkCompiler: Compile a given assignment and upload it
%
% homeworkCompiler will download, parse, verify, package, and distribute
% a given homework assignment.
%
% homeworkCompiler() will begin the process by asking for a folder from
% Google Drive, then asking for an order. assignmentCompiler will then do
% the rest of the necessary operations
%
% homeworkCompiler(I, S, K) will use ID I, Secret S, and Key K to
% authorize with Google Drive. If this is your first time using this, OR
% you have moved this function to a different folder, you will need to
% provide these inputs.
%
%%% Remarks
%
% homeworkCompiler uses the results of testCaseCompiler. It is required
% that all packages within the chosen Google Drive folder be of the
% testCaseCompiler format. For more information on this format, look at the
% documentation for testCaseCompiler
%
% The structure of the release folder will look like this:
%
% release
%   assets
%       student.zip
%       submission.zip
%       resubmission.zip
%   student
%       problemOne_soln.p
%       problemOne.mat
%       allSupportingFiles.*
%   submission
%       rubric.json
%       Solutions
%           problemOne.m
%           ...
%       SupportingFiles
%           problemOne.mat
%           ...
%   resub
%       rubric.json
%       Solutions
%           problemOne.m
%           ...
%       SupportingFiles
%           problemOne.mat
%           ...
function homeworkCompiler(clientId, clientSecret, clientKey)
    % Add correct path
    fprintf(1, 'Setting up Path...');
    addpath(fileparts(mfilename('fullpath')));
    % Steps:
    % 
    % 1. Ask for Google Drive Folder
    % 2. Download all folders and convert/download PDF
    % 3. Ask about order
    % 4. Verify each package separately
    % 5. Compile Assignment
    % 6. Verify Assignment as a whole
    % 7. Upload Assignment to Drive
    
    %% Get Google Authorization
    fprintf(1, 'Done\nAuthorizing...');
    tokenPath = [fileparts(mfilename('fullpath')) filesep 'google.token'];
    fid = fopen(tokenPath, 'rt');
    if fid == -1
        
        % No Token; authorize (if ID and SECRET given; otherwise, die?)
        if nargin == 3 && (~isempty(clientId) && ~isempty(clientSecret) && ~isempty(clientKey))
            token = authorizeWithGoogle(clientId, clientSecret);
            % write all to file
            fid = fopen(tokenPath, 'wt');
            fprintf(fid, '%s\n%s\n%s\n%s', ...
                clientId, ...
                clientSecret, ...
                clientKey, ...
                token);
            fclose(fid);
        else
            throw(MException('ASSIGNMENTCOMPILER:authorization:notEnoughCredentials', ...
                'For Initial Authorization, you must provide all credentials'));
        end
    else
        lines = char(fread(fid)');
        fclose(fid);
        lines = strsplit(lines, newline);
        if numel(lines) == 3
            % need to authorize
            [clientId, clientSecret, clientKey] = deal(lines{:});
            token = authorizeWithGoogle(clientId, clientSecret);
            fid = fopen(tokenPath, 'wt');
            lines{end+1} = token;
            fwrite(fid, strjoin(lines, newline));
            fclose(fid);
        else
            [clientId, clientSecret, clientKey, token] = deal(lines{:});
        end
    end
    token = refresh2access(token, clientId, clientSecret);
    
    % create temporary folder
    workDir = tempname;
    mkdir(workDir);
    currDir = cd(workDir);
    clean = onCleanup(@()(cleaner(workDir, currDir)));
    
    browser = GoogleDriveBrowser(token);
    browser.UIFigure.Name = 'Select Homework Archive';
    uiwait(browser.UIFigure);
    if ~isvalid(browser)
        return;
    elseif isempty(browser.selectedId)
        close(browser.UIFigure);
        fprintf(1, '\n');
        return;
    end
    id = browser.selectedId;
    name = browser.selectedName;
    num = str2double(name(name >= '0' & name <= '9'));
    close(browser.UIFigure);
    % downloadFolder
    fprintf(1, 'Done\nDownloading...');
    downloadFromDrive(id, token, workDir, clientKey);
    [~] = rmdir('release', 's');
    % parse folder names; get the names of the problems...
    %% Parse Problems
    fprintf(1, 'Done\nParsing...');
    flds = dir();
    flds(~[flds.isdir]) = [];
    flds(strncmp({flds.name}, '.', 1)) = [];
    flds(strcmp({flds.name}, 'release')) = [];
    flds(strncmpi({flds.name}, 'abc', 3)) = [];
    % flds are folders that are actually packages; names are those
    problems = {flds.name};
    chooser = ProblemChooser(problems);
    uiwait(chooser.UIFigure);
    if ~isvalid(chooser)
        return;
    end
    problems = chooser.Problems.Items;
    ecProblems = [chooser.Checks.Value];
    ecPoints = [chooser.Points.Value];
    topic = chooser.Topic.Value;
    close(chooser.UIFigure);
    % Now problems is in correct order; compile and engage
    %% Verification
    fprintf(1, 'Done\nVerifying Packages...');
    % Verify each package separately
    % collect supporting file names
    sups = cell(3, numel(problems));
    for p = 1:numel(problems)
        problemDir = [pwd filesep problems{p} filesep];
        sups{1, p} = dir(fullfile(problemDir, 'submission', 'supportingFiles'));
        sups{2, p} = dir(fullfile(problemDir, 'resub', 'supportingFiles'));
        sups{3, p} = dir(fullfile(problemDir, 'student', 'supportingFiles'));
        [~, inds, ~] = unique({sups{1, p}.name});
        sups{1, p} = sups{1, p}(inds);
        [~, inds, ~] = unique({sups{2, p}.name});
        sups{2, p} = sups{2, p}(inds);
        [~, inds, ~] = unique({sups{3, p}.name});
        sups{3, p} = sups{3, p}(inds);
        
        isCorrect = verify([problemDir problems{p} '.m'], ...
            [problemDir filesep 'submission']);
        isCorrect = isCorrect && verify([problemDir problems{p} '.m'], ...
            [problemDir filesep 'resub']);
        isCorrect = isCorrect && verify([problemDir problems{p} '.m'], ...
            [problemDir filesep 'student']);
        if ~isCorrect
            throw(MException('ASSIGNMENTCOMPILER:verify:verificationError', ...
                'Problem %s failed verification', problems{p}));
        end
    end
    % check that no supporting file is the same as problem name
    % no valid 
    probNames = cellstr(string(problems) + ".m");
    if ~isDuplicated(vertcat(sups{1, :})) ...
            || ~isDuplicated(vertcat(sups{2, :})) ...
            || ~isDuplicated(vertcat(sups{3, :}))
        return;
    end
    
    function isValid = isDuplicated(sups)
        sups([sups.isdir]) = [];
        % get names
        names = {sups.name};
        [~, duplicateInds, ~] = unique(names);
        duplicateInds = setdiff(1:numel(names), duplicateInds);
        duplicates = unique(names(duplicateInds));
        duplicates = sups(ismember(names, duplicates));
        problemMask = ismember(probNames, names);
        isValid = isempty(duplicates) && ~any(problemMask);
        if ~isValid
            fprintf(2, 'Failed. ');
        end
        if ~isempty(duplicates)
            % die
            [~, duplicateInds] = sort({duplicates.name});
            duplicates = duplicates(duplicateInds);
            duplicates = fullfile({duplicates.folder}, {duplicates.name});
            % remove base path
            ind = length(fileparts(fileparts(fileparts(fileparts(duplicates{1})))));
            duplicates = extractAfter(duplicates, ind);
            duplicates = strjoin(duplicates, '\n\t');
            fprintf(2, 'The following files are duplicated:\n\t%s\n', duplicates);
        end
        
        % check that no name is same as problems
        if any(problemMask)
            % die
            problemMask = ismember(names, probNames);
            duplicates = sups(problemMask);
            [~, duplicateInds] = sort({duplicates.name});
            duplicates = duplicates(duplicateInds);
            duplicates = fullfile({duplicates.folder}, {duplicates.name});
            % remove base path
            ind = length(fileparts(fileparts(fileparts(fileparts(duplicates{1})))));
            duplicates = extractAfter(duplicates, ind);
            duplicates = strjoin(duplicates, '\n\t');
            fprintf(2, 'The following files duplicate a homework problem:\n\t%s\n', duplicates);
        end
    end
    % all clear. Create release folder and compile
    mkdir('release');
    fprintf(1, 'Done\nCompiling Student...');
    
    %% Create Students
    mkdir(['release' filesep 'student']);
    % for each problem, compile student
    problemInfo = struct('name', problems, ...
        'calls', '', ...
        'banned', '', ...
        'isRecursive', false);
    for p = 1:numel(problems)
        problemDir = [pwd filesep problems{p} filesep];
        %%% Compile student
        % copy over soln file, rename, and pcode
        copyfile([problemDir problems{p} '.m'], ...
            [pwd filesep 'release' filesep 'student' filesep problems{p} '_soln.m']);
        pcode([pwd filesep 'release' filesep 'student' filesep problems{p} '_soln.m'], '-inplace');
        delete([pwd filesep 'release' filesep 'student' filesep problems{p} '_soln.m']);
        
        % copy over supporting files
        if numel(dir(fullfile(problemDir, 'student', 'supportingFiles'))) > 2
            movefile(fullfile(problemDir, 'student', 'supportingFiles', '*'), ...
                fullfile(pwd, 'release', 'student'));
        end
        % rename mat file
        movefile(fullfile(problemDir, 'student', 'inputs.mat'), ...
            fullfile(pwd, 'release', 'student', [problems{p} '.mat']));
        % parse rubric
        fid = fopen(fullfile(problemDir, 'student', 'student.json'), 'rt');
        lines = char(fread(fid)');
        fclose(fid);
        json = jsondecode(lines);
        problemInfo(p).calls = json.calls;
        problemInfo(p).banned = json.banned;
        problemInfo(p).isRecursive = json.isRecursive;
        if ~iscell(json.supportingFiles) && isstring(json.supportingFiles)
            json.supportingFiles = cellstr(json.supportingFiles);
        elseif ~iscell(json.supportingFiles) && ~isempty(json.supportingFiles)
            json.supportingFiles = {json.supportingFiles};
        elseif ~iscell(json.supportingFiles)
            json.supportingFiles = {};
        end
        problemInfo(p).supportingFiles = json.supportingFiles;
    end
    
    % create manifest for student
    lines = createManifest(num, topic, problemInfo);
    fid = fopen([pwd filesep 'release' filesep 'student' filesep sprintf('hw%02d.m', num)], 'wt');
    fwrite(fid, lines);
    fclose(fid);
    % Copy over any PDFs
    if ~isempty(dir([pwd filesep '*.pdf']))
        copyfile([pwd filesep '*.pdf'], ...
            fullfile(pwd, 'release', 'student'));
    end
    % Copy over any orphan .m files (ABCs)
    if ~isempty(dir([pwd filesep 'abcs']))
        copyfile([pwd filesep 'abcs' filesep '*'], ...
            [pwd filesep 'release' filesep 'student' filesep]);
    end
    
    %%% Verify Student
    % for each call, call it!
    fprintf(1, 'Done\nVerifying Student...');
    cd(['release' filesep 'student']);
    for p = 1:numel(problemInfo)
        calls = problemInfo(p).calls;
        for c = 1:numel(calls)
            try
                call = constructCall([problems{p} '_soln'], calls(c).ins, calls(c).outs);
                files = dir;
                caller(call, [problems{p} '.mat']);
                newFiles = dir;
                toDelete = setdiff({newFiles.name}, {files.name});
                for i = 1:numel(toDelete)
                    delete(fullfile(pwd, toDelete{i}));
                end
            catch e
                % die
                throw(MException('ASSIGNMENTCOMPILER:verification:studentCallFailure', ...
                    'Call "%s" failed with error "%s - %s"', call, ...
                    e.identifier, e.message));
            end
        end
    end
    cd(['..' filesep '..']);
    %% Create Submission
    fprintf(1, 'Done\nCompiling Submission...');
    mkdir(['release' filesep 'submission']);
    mkdir(fullfile(pwd, 'release', 'submission', 'SupportingFiles'));
    mkdir(fullfile(pwd, 'release', 'submission', 'Solutions'));
    problemInfo = struct('name', problems, ...
        'calls', '', ...
        'banned', '', ...
        'isRecursive', false, ...
        'supportingFiles', '');
    for p = 1:numel(problems)
        problemDir = [pwd filesep problems{p} filesep];
        % copy over soln file
        copyfile([problemDir problems{p} '.m'], ...
            fullfile(pwd, 'release', 'submission', 'Solutions', [problems{p} '.m']));
        
        % copy over supporting files
        if numel(dir(fullfile(problemDir, 'submission', 'supportingFiles'))) > 2
            movefile(fullfile(problemDir, 'submission', 'supportingFiles', '*'), ...
                fullfile(pwd, 'release', 'submission', 'SupportingFiles'));
        end
        % copy over inputs.mat
        movefile(fullfile(problemDir, 'submission', 'inputs.mat'), ...
            fullfile(pwd, 'release', 'submission', 'SupportingFiles', [problems{p} '.mat']));
        supFiles = dir([problemDir 'submission']);
        supFiles([supFiles.isdir]) = [];
        supFiles(strncmp({supFiles.name}, '.', 1)) = [];
        supFiles(strcmp({supFiles.name}, 'submission.json')) = [];
        supFiles(strcmp({supFiles.name}, 'inputs.mat')) = [];
        problemInfo(p).supportingFiles = {supFiles.name};
        % parse rubric
        fid = fopen(fullfile(problemDir, 'submission', 'submission.json'), 'rt');
        lines = char(fread(fid)');
        fclose(fid);
        json = jsondecode(lines);
        problemInfo(p).calls = json.calls;
        problemInfo(p).banned = json.banned;
        problemInfo(p).isRecursive = json.isRecursive;
        if ~iscell(json.supportingFiles) && isstring(json.supportingFiles)
            json.supportingFiles = cellstr(json.supportingFiles);
        elseif ~iscell(json.supportingFiles) && ~isempty(json.supportingFiles)
            json.supportingFiles = {json.supportingFiles};
        elseif ~iscell(json.supportingFiles)
            json.supportingFiles = {};
        end
        problemInfo(p).supportingFiles = json.supportingFiles;
    end
    % Create overarching rubric
    %
    % Rubric Structure:
    % problem:
    %   name:
    %   isRecursive:
    %   banned:
    %   supportingFiles:
    %   loadFile:
    %   testCases:
    %       call:
    %       initializer: ""
    %       points: ???
    %
    % points split evenly over problems; i.e, if 10 problems, each PROBLEM
    % worth 10 points.later problems get more points if necessary
    problemPoints = ecPoints; %#ok<NASGU>
    problemPoints = zeros(1, numel(problems));
    problemPoints(ecProblems) = ecPoints(ecProblems);
    problemPoints(~ecProblems) = pointAllocate(100, sum(~ecProblems));
    problemJson = struct('name', problems, ...
        'isRecursive', {problemInfo.isRecursive}, ...
        'banned', {problemInfo.banned}, ...
        'supportingFiles', {problemInfo.supportingFiles}, ...
        'loadFile', problems, ...
        'testCases', []);
    for p = 1:numel(problems)
        json = problemJson(p);
        
        json.loadFile = [json.loadFile '.mat'];
        testPoints = pointAllocate(problemPoints(p), numel(problemInfo(p).calls));
        for t = numel(testPoints):-1:1
            testCases(t).inputs = problemInfo(p).calls(t).ins;
            testCases(t).outputs = problemInfo(p).calls(t).outs;
            testCases(t).points = testPoints(t);
        end
        json.testCases = testCases;
        problemJson(p) = json;
    end
    lines = jsonencode(problemJson);
    fid = fopen(fullfile(pwd, 'release', 'submission', 'rubric.json'), 'wt');
    fwrite(fid, lines);
    fclose(fid);
    
    %%% Verification
    % for each call, call it!
    fprintf(1, 'Done\nVerifying Submission...');
    cd(['release' filesep 'submission']);
    for p = 1:numel(problemInfo)
        for c = 1:numel(problemInfo(p).calls)
            try
                call = constructCall(problemInfo(p).name, ...
                    problemInfo(p).calls(c).ins, ...
                    problemInfo(p).calls(c).outs);
                matFile = fullfile(pwd, 'SupportingFiles', [problems{p} '.mat']);
                mFile = fullfile(pwd, 'Solutions', [problems{p} '.m']);
                sups = fullfile(pwd, 'SupportingFiles', problemInfo(p).supportingFiles);
                runCall(call, mFile, matFile, sups);
            catch e
                % die
                throw(MException('ASSIGNMENTCOMPILER:verification:submissionCallFailure', ...
                    'Call "%s" failed with error "%s - %s"', call, ...
                    e.identifier, e.message));
            end
        end
    end
    cd(['..' filesep '..']);
    %% Create Resubmission
    fprintf(1, 'Done\nCompiling Resubmission...');
    mkdir(['release' filesep 'resub']);
    mkdir(fullfile(pwd, 'release', 'resub', 'SupportingFiles'));
    mkdir(fullfile(pwd, 'release', 'resub', 'Solutions'));
    problemInfo = struct('name', problems, ...
        'calls', '', ...
        'banned', '', ...
        'isRecursive', false);
    for p = 1:numel(problems)
        problemDir = [pwd filesep problems{p} filesep];
        % copy over soln file
        copyfile([problemDir problems{p} '.m'], ...
            fullfile(pwd, 'release', 'resub', 'Solutions', [problems{p} '.m']));
        
        % copy over supporting files
        if numel(dir(fullfile(problemDir, 'resub', 'supportingFiles'))) > 2
            movefile(fullfile(problemDir, 'resub', 'supportingFiles', '*'), ...
                fullfile(pwd, 'release', 'resub', 'SupportingFiles'));
        end
        % copy over .mat file
        movefile(fullfile(problemDir, 'resub', 'inputs.mat'), ...
            fullfile(pwd, 'release', 'resub', 'SupportingFiles', [problems{p} '.mat']));
        supFiles = dir([problemDir 'resub']);
        supFiles([supFiles.isdir]) = [];
        supFiles(strncmp({supFiles.name}, '.', 1)) = [];
        supFiles(strcmp({supFiles.name}, 'resub.json')) = [];
        supFiles(strcmp({supFiles.name}, 'inputs.mat')) = [];
        problemInfo(p).supportingFiles = {supFiles.name};
        % parse rubric
        fid = fopen(fullfile(problemDir, 'resub', 'resub.json'), 'rt');
        lines = char(fread(fid)');
        fclose(fid);
        json = jsondecode(lines);
        problemInfo(p).calls = json.calls;
        problemInfo(p).banned = json.banned;
        problemInfo(p).isRecursive = json.isRecursive;
        if ~iscell(json.supportingFiles) && isstring(json.supportingFiles)
            json.supportingFiles = cellstr(json.supportingFiles);
        elseif ~iscell(json.supportingFiles) && ~isempty(json.supportingFiles)
            json.supportingFiles = {json.supportingFiles};
        elseif ~iscell(json.supportingFiles)
            json.supportingFiles = {};
        end
        problemInfo(p).supportingFiles = json.supportingFiles;
    end
    
    problemJson = struct('name', problems, ...
        'isRecursive', {problemInfo.isRecursive}, ...
        'banned', {problemInfo.banned}, ...
        'supportingFiles', {problemInfo.supportingFiles}, ...
        'loadFile', problems, ...
        'testCases', []);
    for p = 1:numel(problems)
        json = problemJson(p);
        
        json.loadFile = [json.loadFile '.mat'];
        testPoints = pointAllocate(problemPoints(p), numel(problemInfo(p).calls));
        for t = numel(testPoints):-1:1
            testCases(t).inputs = problemInfo(p).calls(t).ins;
            testCases(t).outputs = problemInfo(p).calls(t).outs;
            testCases(t).points = testPoints(t);
        end
        json.testCases = testCases;
        problemJson(p) = json;
    end
    lines = jsonencode(problemJson);
    fid = fopen(fullfile(pwd, 'release', 'resub', 'rubric.json'), 'wt');
    fwrite(fid, lines);
    fclose(fid);
    
    %%% Verification
    % for each call, call it!
    fprintf(1, 'Done\nVerifying Resubmission...');
    cd(['release' filesep 'resub']);
    for p = 1:numel(problemInfo)
        for c = 1:numel(problemInfo(p).calls)
            try
                call = constructCall(problemInfo(p).name, ...
                    problemInfo(p).calls(c).ins, ...
                    problemInfo(p).calls(c).outs);
                matFile = fullfile(pwd, 'SupportingFiles', [problems{p} '.mat']);
                mFile = fullfile(pwd, 'Solutions', [problems{p} '.m']);
                sups = fullfile(pwd, 'SupportingFiles', problemInfo(p).supportingFiles);
                runCall(call, mFile, matFile, sups);
            catch e
                % die
                throw(MException('ASSIGNMENTCOMPILER:verification:resubmissionCallFailure', ...
                    'Call "%s" failed with error "%s - %s"', call, ...
                    e.identifier, e.message));
            end
        end
    end
    cd(['..' filesep '..']);
    %% Create Assets
    % Assets include:
    % * submission_grader.zip - submission grading archive
    % * resubmission_grader.zip - resubmission grading archive
    % * HW##.zip - Student redistributable
    % * HW##_Submission.zip - Submission Test Case redistributable
    % * HW##_Resubmission.zip - Resubmission Test Case redistributable
    % * HW##_Solutions.zip - Solution file redistributable
    % * HW##_TAs.zip - Complete test case redistributable
    fprintf(1, 'Done\nCreating Assets...');
    mkdir(fullfile(pwd, 'release', 'assets'));
    % create zips
    zip(fullfile(pwd, 'release', 'assets', sprintf('HW%02d.zip', num)), ...
        fullfile(pwd, 'release', 'student', '*'));
    zip(fullfile(pwd, 'release', 'assets', 'submission_grader.zip'), ...
        fullfile(pwd, 'release', 'submission', '*'));
    zip(fullfile(pwd, 'release', 'assets', 'resubmission_grader.zip'), ...
        fullfile(pwd, 'release', 'resub', '*'));
    zip(fullfile(pwd, 'release', 'assets', sprintf('HW%02d_Submission.zip', num)), ...
        fullfile(pwd, 'release', 'submission', 'SupportingFiles', '*.mat'));
    zip(fullfile(pwd, 'release', 'assets', sprintf('HW%02d_Resubmission.zip', num)), ...
        fullfile(pwd, 'release', 'resub', 'SupportingFiles', '*.mat'));
    zip(fullfile(pwd, 'release', 'assets', sprintf('HW%02d_Solutions.zip', num)), ...
        fullfile(pwd, 'release', 'submission', 'Solutions', '*.m'));
    % copy over all test case MAT files
    testCaseTmpDir = tempname;
    mkdir(testCaseTmpDir);
    % copy over all mat files
    % copy students
    copyfile(fullfile(pwd, 'release', 'student', '*'), ...
        testCaseTmpDir);
    files = dir(fullfile(pwd, 'release', 'submission', 'SupportingFiles'));
    files([files.isdir]) = [];
    for f = 1:numel(files)
        % if a mat file, deal with separately
        if endsWith(files(f).name, '.mat')
            copyfile(fullfile(files(f).folder, files(f).name), ...
                fullfile(testCaseTmpDir, [files(f).name(1:end-4) '_submission.mat']));
        else
            copyfile(fullfile(files(f).folder, files(f).name), ...
                fullfile(testCaseTmpDir, files(f).name));
        end
    end
    files = dir(fullfile(pwd, 'release', 'resub', 'SupportingFiles'));
    files([files.isdir]) = [];
    for f = 1:numel(files)
        % if a mat file, deal with separately
        if endsWith(files(f).name, '.mat')
            copyfile(fullfile(files(f).folder, files(f).name), ...
                fullfile(testCaseTmpDir, [files(f).name(1:end-4) '_submission.mat']));
        else
            copyfile(fullfile(files(f).folder, files(f).name), ...
                fullfile(testCaseTmpDir, files(f).name));
        end
    end
    zip(fullfile(pwd, 'release', 'assets', sprintf('HW%02d_TAs.zip', num)), ...
        fullfile(testCaseTmpDir, '*'));
    rmdir(testCaseTmpDir, 's');
    
    
    %% Upload to Drive
    fprintf(1, 'Done\nUploading...');
    uploadToDrive([pwd filesep 'release'], id, token, clientKey);
    fprintf(1, 'Done\n');
end

function cleaner(work, curr)
    cd(curr);
    [~] = rmdir(work, 's');
end

%%% pointAllocate: Allocate points to a distribution
function dist = pointAllocate(points, num)
    base = floor(points / num);
    extra = points - (base * num);
    % add extra to end
    dist(1:num) = base;
    dist(end) = dist(end) + extra;
end
function runCall(call, mFile, loadFile, supportingFiles)
    workDir = tempname;
    mkdir(workDir);
    safeDir = cd(workDir);
    cleaner = onCleanup(@()(cd(safeDir)));
    % create loadFile
    copyfile(mFile, workDir);
    if nargin == 4
        for s = 1:numel(supportingFiles)
            copyfile(supportingFiles{s}, workDir);
        end
    end
    caller(call, loadFile);
    cd(safeDir);
    rmdir(workDir, 's');
end
function caller(call, loadFile)
    load(loadFile); %#ok<LOAD>
    f = figure('Visible', 'off');
    evalc(call);
    close(f);
end