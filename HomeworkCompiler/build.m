%% build: Build the Homework Compiler
%
% build will create the ZIP necessary to install the Homework
% Compiler.
%
% build() will create the installation package, ready to be distributed as
% a ZIP archive.
%
%%% Remarks
%
% This does _not_ do any testing, so make sure to test it before building!
%
function build
% create bin folder
userDir = cd(fileparts(mfilename('fullpath')));
cleaner = onCleanup(@()(cd(userDir)));
if isfolder('bin')
    [~] = rmdir('bin', 's');
end
mkdir('bin');
% copy everything EXCEPT for build (and bin)
files = [dir('.'); dir(['..' filesep 'GoogleDriveIntegration'])];
files([files.isdir]) = [];
files(strcmp({files.name}, mfilename)) = [];
files(endsWith({files.name}, {'.m~', '.asv'})) = [];

% for each file, copy to bin
for f = files'
    copyfile([f.folder filesep f.name], 'bin');
end
% copy verify.m
copyfile(['..' filesep 'TestCaseCompiler' filesep 'verify.m'], 'bin');

% zip
zip('homeworkCompilerRelease.zip', 'bin');
end