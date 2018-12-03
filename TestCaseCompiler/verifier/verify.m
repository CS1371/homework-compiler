%% verify: Verify that problem packages are error-free
%
% Checks a single homework problem package to ensure that the solution
% function runs all the test cases in that package without error.
%
% R = VERIFY(S, P) takes an absolute path S to a solution file and an
% absolute path P to a problem package (either 'student', 'submission', or
% 'resubmission' folder under the root package directory) and verifies the
% inputs in the package (via the rubric json) for correctness. R is a
% logical true if all the tests succeed, and false if any test failed.
%
% [R, N, M] = VERIFY(S, P) does the above, but also returns additional
% diagnostic information. N is a double vector listing the test cases that
% failed, if any. M is a 1xlength(N) cell array of MExceptions that is
% empty if R is true, and contains the details of the error(s) (including
% which test case(s) errored and why) if R is false.
%
%%% Remarks
%
% If a function passes this verification, that does not necessarily mean
% that it is correct in the context of the homework problem. It only means
% that the function does not error on any of the test cases specified in
% the rubric json.
%
%%% Exceptions
%
% verify() throws the following exceptions:
%
% TESTCASE:verifier:verify:invalidPackage if any part of the problem
% package fails to meet the specification, including but not limited to
% missing solution file, missing supporting files, or invalid json file
% format.
%
%%% Unit Tests
%
%   Let P be the full path to a valid problem package containing test cases
%	which do not contain any errors.
%
%   [R, M] = verify(S, P);
%
%   R -> true; M -> '';
%
%   Let P be the full path to an invalid problem package.
%
%   [R, M] = verify(S, P);
%
%   Exception raised: invalidPackage
%
% (c) 2018 CS1371 (J. Htay, D. Profili, A. Rao, H. White)

function [result, failedCases, msg] = verify(pathToSolnFile, packagePath)

% check the inputs for basic validity (mostly just that they exist)
p = inputParser;
p.addRequired('pathToSolnFile', @(x)(exist(x, 'file')));
p.addRequired('packagePath', @(x)(exist(x, 'file')));
parse(p, pathToSolnFile, packagePath);

% NOTE: not sure if this is necessary
pathToSolnFile = p.Results.pathToSolnFile;
packagePath = p.Results.packagePath;

% initial setup
initialDir = cd();

% directory for the function testing folder
sandboxDir = tempname;
c = onCleanup(@()(cleanup(initialDir, sandboxDir)));

% if isempty(probName)
%     throw(MException('TESTCASE:verifier:verify:invalidPackage', ...
%         'Invalid package path'));
% end

% get the list of files in the package path
[~, pkgName] = fileparts(packagePath);
rubric = [packagePath filesep pkgName '.json'];

if ~exist(rubric, 'file')
    throw(MException('TESTCASE:verifier:verify:invalidPackage', ...
        'Invalid package format'));
end

% get the rubric information containing the test cases
rubricSt = jsondecode(fileread(rubric));

if ~exist(pathToSolnFile, 'file')
    throw(MException('TESTCASE:verifier:verify:invalidPackage', ...
        'Solution file not found in package'));
end

% now, get all required info from the structure

% now check and make sure everything is there
reqdFields = {'calls', 'loadFile', 'supportingFiles'};
missingFields = find([~isfield(rubricSt, 'calls'), ~isfield(rubricSt, 'loadFile'), ...
        ~isfield(rubricSt, 'supportingFiles')]);

if ~isempty(missingFields)
    missing = strjoin(reqdFields(missingFields), ',');
%     for i = 1:length(missingFields)
%         missing = [missing, ', ', reqdFields{missingFields(i)}];
%     end
%     missing = missing(3:end);
    throw(MException('TESTCASE:verifier:verify:invalidPackage', ...
        'Package json has missing field(s): %s', missing)); 
end

if rubricSt.isRecursive && ~checkRecur([pwd filesep rubricSt.name '.m'])
    throw(MException('TESTCASE:verifier:verify:notRecursive', ...
        'Solution is not recursive, yet recursion is mandated'));
end
% collect all the function calls
calls = rubricSt.calls;

% cell array of input files
inputFiles = rubricSt.loadFile;

% supporting files
supFiles = rubricSt.supportingFiles;

% if the supporting files list is not empty, the supportingFiles directory
% in the package must exist
if ~isempty(supFiles) && ~exist([packagePath filesep 'supportingFiles'], 'file')
        throw(MException('TESTCASE:verifier:verify:invalidPackage', ...
        'Supporting files not found in package'));

end

actualSupFiles = dir([packagePath filesep 'supportingFiles']);
actualSupFiles = {actualSupFiles.name};
actualSupFiles = actualSupFiles(~(strcmp(actualSupFiles, '.') | strcmp(actualSupFiles, '..')));
if ~isempty(setdiff(actualSupFiles, supFiles))
    % files in the supFiles folder not accounted for
    extraFiles = strjoin(setdiff(actualSupFiles, supFiles), ',');
    throw(MException('TESTCASE:verifier:verify:invalidPackage', ...
        'Extra supporting files found in /supportingFiles: %s', extraFiles));
end

if ~iscell(inputFiles)
    inputFiles = {inputFiles};
end

% now, need to create a 'sandbox' folder to run the function in
% mkdir(sandboxDir); copy all supporting files to sandbox directory
copyfile([packagePath filesep '*'], sandboxDir);
% copy the solution function itself to sandbox directory
copyfile(pathToSolnFile, sandboxDir);
% move the supporting files into the directory with everything else
if ~isempty(supFiles)
    copyfile([packagePath filesep 'supportingFiles' filesep '*'], sandboxDir);
end

% add the temp sandbox folder to path so that supporting files can be
% accessed
% addpath(sandboxDir);


% test the function in the sandbox on each of the test cases
result = true;
failedCases = [];
msg = {};
cd(sandboxDir);


for i = length(calls):-1:1
    try
        % create call
        call = ['[' strjoin(calls(i).outs, ', ') '] = ' rubricSt.name '(' strjoin(calls(i).ins, ', ') ');'];
        funcWrapper(call, inputFiles);
    catch ME
        failedCases(i) = i;
        msg{i} = ME;
        result = false;
    end
end
failedCases(failedCases == 0) = [];
msg(cellfun(@isempty, msg)) = [];

cd(initialDir);
% done verifying

end

% Try and reset everything to before verifier was run
function cleanup(initialDir, ~)
% try
%     cd(toDelete); cd('..'); % go up one from the delete dir [~] =
%     rmdir(toDelete, 's'); % delete it from above
% catch ME
%     warning('It didn''t close properly')
% end

cd(initialDir);
% rmpath(sandboxDir);

end

%% funcWrapper Wrapper for eval()ing function calls
% 
% Called to reduce workspace clutter in the main verify() function.
%
function funcWrapper(toRun, inp)
    beforeFiles = dir();
    beforeFiles = {beforeFiles.name};
    for i = 1:length(inp)
        load(inp{i});
    end
    eval(toRun);
    afterFiles = dir();
    afterFiles = {afterFiles.name};
    
    newFiles = setdiff(afterFiles, beforeFiles);
    % delete the generated files
    cellfun(@delete, newFiles);
    if any(cellfun(@(x)(~contains(x, '_soln.')), newFiles))
        error('Created files did not include _soln suffix.');
    end


end