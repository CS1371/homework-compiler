%% createManifest: Create the Homework Manifest File
%
% createManifest will create the correct homework file.
%
% M = createManifest(N, T, P) will create a manifest file for homework num
% N, with topic T, and problems P, outputing the new code as string M.
%
%%% Remarks
%
% P is a structure array that must have the following organization:
%
% Each element is a single problem with:
%
%   name: The problem name
%   calls: The problem calls, as a cell array
function lines = createManifest(num, topic, problems)
    fid = fopen('manifestTemplate.m', 'rt');
    lines = char(fread(fid)');
    fclose(fid);
    lines = strrep(lines, '<<NUM>>', sprintf('%02d', num));
    lines = strrep(lines, '<<TOPIC>>', topic);
    firstFile = sprintf('hw%02d', num);
    filesToSubmit = ['% - ' strjoin([{firstFile} {problems.name}], '.m\n% - ') '.m'];
    lines = strrep(lines, '% <<PROBLEMS>>', filesToSubmit);
    
    % create test cases
    % for each problem, looks like:
    %%% problemName
    %
    %   load('problemName.mat');
    %
    %   call1
    %   solnCall1
    %   isequalCheck1
    %
    %   call2
    %   solnCall2
    %   isequalCheck2
    %
    testCases = cell(1, numel(problems));
    for p = 1:numel(problems)
        HEADER_LINES = 5;
        LINES_PER_CALL = 4;
        probStatement = cell(1, HEADER_LINES + (LINES_PER_CALL * numel(problems(p).calls)));
        probStatement{1} = ['%% ' problems(p).name];
        probStatement{2} = '%';
        probStatement{3} = ['%    load(''' problems(p).name '.mat'');'];
        probStatement{4} = '%';
        % for each test case, engage
        counter = HEADER_LINES;
        for t = 1:numel(problems(p).calls)
            c = problems(p).calls(t);
            call = constructCall(problems(p).name, c.ins, c.outs);
            probStatement{counter} = ['%    ' call ';'];
            probStatement{counter+1} = ['%    ' orig2soln(call) ';'];
            check = constructCheck(c.outs);
            probStatement{counter+2} = sprintf('check%d = %s;', t, check);
            probStatement{counter+3} = '%';
            counter = counter + LINES_PER_CALL;
        end
        probStatement{end} = '%';
        testCases{p} = strjoin(probStatement, newline);
    end
    testCases = strjoin(testCases, newline);
    lines = strrep(lines, '% <<TESTCASE>>', testCases);
end