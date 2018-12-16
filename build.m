%% Build: Builds the Homework Compiler Collection
%
% build will build the HCC
%
% build(A1, ...) will execute the two build scripts with arguments A1, ...
%
%%% Remarks
%
% The HCC is the Homework Compiler Collection, and includes both the
% Homework Compiler and the Test Case Compiler.
function build(varargin)
    safeDir = cd(fullfile(fileparts(mfilename('fullpath')), 'HomeworkCompiler'));
    cleaner = onCleanup(@()(cd(safeDir)));
    
    build(varargin{:});
    cd(fullfile(fileparts(mfilename('fullpath')), 'TestCaseCompiler'));
    build(varargin{:});
end