%% assignmentCompiler: Compile a given assignment and upload it
%
% assignmentCompiler will download, parse, verify, package, and distribute
% a given homework assignment.
%
% assignmentCompiler() will begin the process by asking for a folder from
% Google Drive, then asking for an order. assignmentCompiler will then do
% the rest of the necessary operations
%
% assignmentCompiler(P1, V1, ...) will use Name-Value pairs P and V to
% augment the behavior. The possible pairs are discussed in Remarks
%
%%% Remarks
%
% assignmentCompiler uses the results of testCaseCompiler. It is required
% that all packages within the chosen Google Drive folder be of the
% testCaseCompiler format. For more information on this format, look at the
% documentation for testCaseCompiler
%
% Pairs
%
% Pair names are case-insensitive.
%
% ClientID: A character vector or scalar string. The Google Client ID.
%
% ClientSecret: A character vector or scalar string. The Google Client
% Secret.
%
% ClientKey: A character vector or scalar string. The Google Client Key.
function assignmentCompiler(varargin)
    
    parser = inputParser();
    parser.FunctionName = 'assignmentCompiler';
    parser.CaseSensitive = false;
    parser.StructExpand = true;
    parser.addParameter('ClientID', '', @(u)(ischar(u) || (isstring(u) && isscalar(u))));
    parser.addParameter('ClientSecret', '', @(u)(ischar(u) || (isstring(u) && isscalar(u))));
    parser.addParameter('ClientKey', '', @(u)(ischar(u) || (isstring(u) && isscalar(u))));
    parser.parse(varargin{:});
    
    clientId = parser.Results.ClientID;
    clientSecret = parser.Results.ClientSecret;
    clientKey = parser.Results.ClientKey;
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
    tokenPath = [fileparts(mfilename('fullpath')) filesep 'google.token'];
    fid = fopen(tokenPath, 'rt');
    if fid == -1
        % No Token; authorize (if ID and SECRET given; otherwise, die?)
        if ~isempty(clientId) && ~isempty(clientSecret)
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
            % Die
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
    if isempty(browser.selectedId)
        % die
    end
    id = browser.selectedId;
    name = browser.selectedName;
    num = str2double(name(name >= '0' & name <= '9'));
    close(browser.UIFigure);
    % downloadFolder
    downloadFromDrive(id, token, workDir, clientKey);
    % parse folder names; get the names of the problems...
    %% Parse Problems
    flds = dir();
    flds(~[flds.isdir]) = [];
    flds(strncmp({flds.name}, '.', 1)) = [];
    flds(strcmp({flds.name}, 'release')) = [];
    % flds are folders that are actually packages; names are those
    problems = {flds.name};
    chooser = ProblemChooser();
    chooser.Problems.Items = problems;
    chooser.Problems.ItemsData = 1:numel(problems);
    uiwait(chooser.UIFigure);
    problems = chooser.Problems.Items;
    close(chooser.UIFigure);
    % Now problems is in correct order; compile and engage
    %% Verification
    % Verify!
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
    lines = createManifest(num, topic, problems);
    fid = fopen([pwd filesep 'release' filesep 'student' filesep sprintf('hw%02d.m', num)], 'wt');
    fwrite(fid, lines);
    fclose(fid);
    
    %% Create Submission
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
    problemPoints = pointAllocate(100, numel(problems));
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
            testCases(t).call = problemInfo(p).calls{t};
            testCases(t).initializer = '';
            testCases(t).points = testPoints(t);
        end
        json.testCases = testCases;
        problemJson(p) = json;
    end
    lines = jsonencode(problemJson);
    fid = fopen([pwd filesep 'release' filesep 'submission' filesep 'rubric.json'], 'wt');
    fwrite(fid, lines);
    fclose(fid);
    
    %% Create Resubmission
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
    
    problemPoints = pointAllocate(100, numel(problems));
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
            testCases(t).call = problemInfo(p).calls{t};
            testCases(t).initializer = '';
            testCases(t).points = testPoints(t);
        end
        json.testCases = testCases;
        problemJson(p) = json;
    end
    lines = jsonencode(problemJson);
    fid = fopen([pwd filesep 'release' filesep 'resubmission' filesep 'rubric.json'], 'wt');
    fwrite(fid, lines);
    fclose(fid);
    
    %% Upload to Drive
    uploadToDrive([pwd filesep 'release'], id, clientToken, clientKey);
    
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
    