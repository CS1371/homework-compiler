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
function homeworkCompiler(clientId, clientSecret, clientKey)
    % Add correct path
    fprintf(1, 'Setting up Path...');
    addpath(pwd);
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
        % line 1 will be id, 2 secret, 3 key, 4 token
        lines = strsplit(lines, newline);
        [clientId, clientSecret, clientKey, token] = deal(lines{:});
    end
    token = refresh2access(token, clientId, clientSecret);
    
    % create temporary folder
    workDir = tempname;
    mkdir(workDir);
    currDir = cd(workDir);
    clean = onCleanup(@()(cleaner(workDir, currDir)));
    
    browser = GoogleDriveBrowser(token);
    uiwait(browser.UIFigure);
    if ~isvalid(browser) || isempty(browser.selectedId)
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
    verify = @(varargin)(true);
    for p = 1:numel(problems)
        problemDir = [pwd filesep problems{p} filesep];
        isCorrect = verify([problemDir problems{p} '.m'], ...
            [problemDir filesep 'submission']);
        isCorrect = isCorrect && verify([problemDir problems{p} '.m'], ...
            [problemDir filesep 'resubmission']);
        isCorrect = isCorrect && verify([problemDir problems{p} '.m'], ...
            [problemDir filesep 'student']);
        if ~isCorrect
            throw(MException('ASSIGNMENTCOMPILER:verify:verificationError', ...
                'Problem %s failed verification', problems{p}));
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
        copyfile([problemDir 'student'], ...
            [pwd filesep 'release' filesep 'student']);
        % rename mat file
        movefile([pwd filesep 'release' filesep 'student' filesep 'inputs.mat'], ...
            [pwd filesep 'release' filesep 'student' filesep problems{p} '.mat']);
        % parse rubric
        fid = fopen([pwd filesep 'release' filesep 'student' filesep 'rubric.json'], 'rt');
        lines = char(fread(fid)');
        fclose(fid);
        json = jsondecode(lines);
        problemInfo(p).calls = json.calls;
        problemInfo(p).banned = json.banned;
        problemInfo(p).isRecursive = json.isRecursive;
        % delete rubric
        delete([pwd filesep 'release' filesep 'student' filesep 'rubric.json']);
    end
    
    % create manifest for student
    lines = createManifest(num, topic, problemInfo);
    fid = fopen([pwd filesep 'release' filesep 'student' filesep sprintf('hw%02d.m', num)], 'wt');
    fwrite(fid, lines);
    fclose(fid);
    % Copy over any PDFs
    copyfile([pwd filesep '*.pdf'], ...
        [pwd filesep 'release' filesep 'student' filesep]);
    % Copy over any orphan .m files (ABCs)
    copyfile([pwd filesep '*.m'], ...
        [pwd filesep 'release' filesep 'student' filesep]);
    
    %%% Verify Student
    % for each call, call it!
    fprintf(1, 'Done\nVerifying Student...');
    cd(['release' filesep 'student']);
    for p = 1:numel(problemInfo)
        calls = problemInfo(p).calls;
        for c = 1:numel(calls)
            try
                call = constructCall(problems{p}, calls(c).ins, calls(c).outs);
                runCall(call, [problems{p} '.mat']);
            catch e
                % die
                throw(MException('ASSIGNMENTCOMPILER:verification:studentCallFailure', ...
                    'Call "%s" failed with error "%s - %s"', problemInfo(p).calls{c}, ...
                    e.identifier, e.message));
            end
        end
    end
    cd(['..' filesep '..']);
    %% Create Submission
    fprintf(1, 'Done\nCompiling Submission...');
    mkdir(['release' filesep 'submission']);
    problemInfo = struct('name', problems, ...
        'calls', '', ...
        'banned', '', ...
        'isRecursive', false, ...
        'supportingFiles', '');
    for p = 1:numel(problems)
        problemDir = [pwd filesep problems{p} filesep];
        % copy over soln file
        copyfile([problemDir problems{p} '.m'], ...
            [pwd filesep 'release' filesep 'submission' filesep problems{p} '.m']);
        
        % copy over supporting files
        copyfile([problemDir 'submission'], ...
            [pwd filesep 'release' filesep 'submission']);
        supFiles = dir([problemDir 'submission']);
        supFiles([supFiles.isdir]) = [];
        supFiles(strncmp({supFiles.name}, '.', 1)) = [];
        supFiles(strcmp({supFiles.name}, 'rubric.json')) = [];
        supFiles(strcmp({supFiles.name}, 'inputs.mat')) = [];
        problemInfo(p).supportingFiles = {supFiles.name};
        % rename mat file
        movefile([pwd filesep 'release' filesep 'submission' filesep 'inputs.mat'], ...
            [pwd filesep 'release' filesep 'submission' filesep problems{p} '.mat']);
        % parse rubric
        fid = fopen([pwd filesep 'release' filesep 'submission' filesep 'rubric.json'], 'rt');
        lines = char(fread(fid)');
        fclose(fid);
        json = jsondecode(lines);
        problemInfo(p).calls = json.calls;
        problemInfo(p).banned = json.banned;
        problemInfo(p).isRecursive = json.isRecursive;
        % delete rubric
        delete([pwd filesep 'release' filesep 'submission' filesep 'rubric.json']);
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
    fid = fopen([pwd filesep 'release' filesep 'submission' filesep 'rubric.json'], 'wt');
    fwrite(fid, lines);
    fclose(fid);
    
    %%% Verification
    % for each call, call it!
    fprintf(1, 'Done\Verifying Submission...');
    cd(['release' filesep 'submission']);
    for p = 1:numel(problemInfo)
        for c = 1:numel(problemInfo(p).calls)
            try
                call = constructCall(problemInfo(p).name, ...
                    problemInfo(p).calls(c).ins, ...
                    problemInfo(p).calls(c).outs);
                runCall(call, [problems{p} '.mat']);
            catch e
                % die
                throw(MException('ASSIGNMENTCOMPILER:verification:submissionCallFailure', ...
                    'Call "%s" failed with error "%s - %s"', problemInfo(p).calls{c}, ...
                    e.identifier, e.message));
            end
        end
    end
    cd(['..' filesep '..']);
    %% Create Resubmission
    fprintf(1, 'Done\Compiling Resubmission...');
    mkdir(['release' filesep 'resubmission']);
    problemInfo = struct('name', problems, ...
        'calls', '', ...
        'banned', '', ...
        'isRecursive', false);
    for p = 1:numel(problems)
        problemDir = [pwd filesep problems{p} filesep];
        % copy over soln file
        copyfile([problemDir problems{p} '.m'], ...
            [pwd filesep 'release' filesep 'resubmission' filesep problems{p} '.m']);
        
        % copy over supporting files
        copyfile([problemDir 'resubmission'], ...
            [pwd filesep 'release' filesep 'resubmission']);
        supFiles = dir([problemDir 'submission']);
        supFiles([supFiles.isdir]) = [];
        supFiles(strncmp({supFiles.name}, '.', 1)) = [];
        supFiles(strcmp({supFiles.name}, 'rubric.json')) = [];
        supFiles(strcmp({supFiles.name}, 'inputs.mat')) = [];
        problemInfo(p).supportingFiles = {supFiles.name};
        % rename mat file
        movefile([pwd filesep 'release' filesep 'resubmission' filesep 'inputs.mat'], ...
            [pwd filesep 'release' filesep 'resubmission' filesep problems{p} '.mat']);
        % parse rubric
        fid = fopen([pwd filesep 'release' filesep 'resubmission' filesep 'rubric.json'], 'rt');
        lines = char(fread(fid)');
        fclose(fid);
        json = jsondecode(lines);
        problemInfo(p).calls = json.calls;
        problemInfo(p).banned = json.banned;
        problemInfo(p).isRecursive = json.isRecursive;
        % delete rubric
        delete([pwd filesep 'release' filesep 'resubmission' filesep 'rubric.json']);
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
    fid = fopen([pwd filesep 'release' filesep 'resubmission' filesep 'rubric.json'], 'wt');
    fwrite(fid, lines);
    fclose(fid);
    
    %%% Verification
    % for each call, call it!
    fprintf(1, 'Done\Verifying Resubmission...');
    cd(['release' filesep 'resubmission']);
    for p = 1:numel(problemInfo)
        for c = 1:numel(problemInfo(p).calls)
            try
                call = constructCall(problemInfo(p).name, ...
                    problemInfo(p).calls(c).ins, ...
                    problemInfo(p).calls(c).outs);
                runCall(call, ...
                    [problems{p} '.mat']);
            catch e
                % die
                throw(MException('ASSIGNMENTCOMPILER:verification:resubmissionCallFailure', ...
                    'Call "%s" failed with error "%s - %s"', problemInfo(p).calls{c}, ...
                    e.identifier, e.message));
            end
        end
    end
    cd(['..' filesep '..']);
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

function runCall(call, loadFile)
    load(loadFile); %#ok<LOAD>
    evalc(call);
end
    