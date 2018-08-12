%% buildTestCase: Builds the Test Case Compiler
%
% buildTestCase will build the Test Case compiler from scratch, including
% the JARs, and will package it into its own ZIP archive.
%
% buildTestCase() will build the archive.
%
function buildTestCase()
% cd to our own folder

orig = cd(fileparts(mfilename('fullpath')));

% Compile Java
if isunix
    [~, ~] = system('./gradlew build');
elseif ispc
    [~, ~] = system('.\gradlew.bat build');
end

% Create ZIP:
%   * compiled JAR
%   * everything in interface
%   * everything in GoogleDriveIntegration
%   * README.md

cleaner = onCleanup(@()(cd(orig)));
paths = {
    [pwd filesep 'build' filesep 'libs' filesep 'TestCaseCompiler.jar'], ...
    [pwd filesep 'interface' filesep '*'], ...
    [fileparts(pwd) filesep 'GoogleDriveIntegration' filesep '*'], ...
    [pwd filesep 'README.md']
};

zip('../testCaseCompiler.zip', paths);

end