%% package: Create a single package for the Problem
%
% package will take in information about the given package, and will create
% a package in the current directory
%
% package(T, O, I, F, V, P, N, R, B, Z) will use type T, output base name
% O, input base name I, function name F, input values V, supporting file
% paths P, number of test cases N, banned functions B, logical recursive
% flag R, and initializer Z to create the specified package.
%
%%% Remarks
%
% package is used to create a single, self-contained package that can be
% one of three types: Student, Submission, or Resubmission.
%
% T must be a character vector or string scalar that is one of the
% following three options:
%
% * student: The student's set of test case; what the student receives in
% hw##.m
% * submission: The test suite for grading the original submissions
% * resub: The test suite for grading the resubmissions
%
% T is actually a path, with the option appended to the end.
%
% I and O must both be valid variable names. The class and number of these
% inputs defines the behavior:
%
% * If it is a character vector or string scalar, then the inputs/outputs 
% are incremented linearly: For example, if I is 'hello', then the first 
% input will be 'hello1', the second 'hello2', etc. This linear trend 
% goes beyond the first test case.
% * If it is a cell array of character vectors or a string array, then it
% must be the same length as the number of inputs or outputs. In this case,
% the first case has '1' appended, the second '2', and so on. For example,
% if the function has two outputs, and O = {'hello', 'world'}, then the
% first outputs for test case 1 would be [hello1, world1].
%
% V must be a cell array of values, whose length is equal to the number of
% test cases times the number of inputs to the function.
%
% P is a cell array of character vectors or a string array, where each
% entry is the absolute path to the supporting file.
%
% If R is true, then the student will receive no points if their solution
% is not recursive.
%
% (c) 2018 CS1371 (J. Htay, D. Profili, A. Rao, H. White)



function package(path, out, ins, name, vals, paths, num, recurs, ban)
    

    [~, type, ~] = fileparts(path);
    [fld, fName, ~] = fileparts(name);
    
    tmp = cd(fld);
    numIns = nargin(fName);
    numOuts = nargout(fName);
    cd(tmp);
    addpath(fileparts(mfilename('fullpath')));
    tDir = tempname;
    mkdir(tDir);
    
    cl = onCleanup(@()(cleaner(tmp, tDir)));
    cd(tDir);
    
%     ins = generateVarNames(in, numIns, num);
    outs = generateVarNames(out, numOuts, num);
    
    % num vals = nargin * numTests
    if numel(vals) ~= (numIns * num)
        throw(MException('TESTCASE:packager:package:argumentNumberMismatch', ...
            'Expected %d inputs; got %d instead', ...
            (numIns * num), numel(vals)));
    end
    
    % input / output bases are OK; we have enough input values.
    createInputs(ins, vals);
    % create supportingFiles
    mkdir('supportingFiles');
    for p = 1:numel(paths)
        [~, tmpName, tmpExt] = fileparts(paths{p});
        if strcmpi(tmpName, fName) && strcmp(tmpExt, '.m')
            throw(MException('TESTCASE:packager:package:invalidSupportingFile', ...
                'You cannot include the function as a supporting file'));
        end
        copyfile(paths{p}, 'supportingFiles');
        paths{p} = [tmpName tmpExt];
        if sum(strcmpi(paths, paths{p})) > 1
            throw(MException('TESTCASE:packager:package:duplicateSupportingFile', ...
                'File "%s" was already specified', paths{p}));
        end
    end
    
    % create JSON
    % create structure
    % structure has:
    %   name
    %   isRecursive
    %   banned
    %   supportingFiles
    %   loadFile
    %   testCases:
    %       calls
    % --FOR INTERNAL LOADING USE ONLY--
    %   ins
    %   outs
    %   outBase
    json.name = fName;
    json.isRecursive = recurs;
    json.banned = ban;
    json.loadFile = 'inputs.mat';
    json.supportingFiles = paths;
%     json.initializer = '';
    % these fields are for internal loading use only
    json.ins = ins;
    json.outs = outs;
    json.outBase = out;
    
    % create test cases
    ins = ins(end:-1:1);
    outs = outs(end:-1:1);
    calls = cell(1, num);
    for t = num:-1:1
        % create call
        calls{t} = ['[' strjoin(outs(numOuts:-1:1), ', ') '] = ' fName '(' strjoin(ins(numIns:-1:1), ', ') ');'];
        outs(1:numOuts) = [];
        ins(1:numIns) = [];
    end
    json.calls = calls;
    json = jsonencode(json);
    fid = fopen([type '.json'], 'wt');
    fwrite(fid, json);
    fclose(fid);
    
        % try to make path; if already exists, delete and recreate
    if isfolder(path)
        [~] = rmdir(path, 's');
    end
    % create directory
    mkdir(path);
    copyfile('./*', path);
    
end


function cleaner(path, rmPath)
    cd(path);
    rmdir(rmPath, 's');
end
