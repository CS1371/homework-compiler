%% testCaseCompiler: Create and Edit Test Cases
%
% testCaseCompiler will launch a User Interface that facilitates the
% creation, editing, and uploading of test cases.
%
% testCaseCompiler() will launch a blank Test Case Compiler GUI, ready to
% create a brand new Test Case set.
%
% testCaseCompiler(H, P) will use homework number H and problem name P to
% download and allow editing of an existing test case set. If it can't be
% found, it behaves as if no arguments were given.
%
%%% Remarks
%
% This function provides the "bridge" between MATLAB and the Java UI.
% However, this function doesn't block
function testCaseCompiler()
% make sure engine is shared
if ~matlab.engine.isEngineShared
    matlab.engine.shareEngine;
end

% Construct the JAR call
% java -Djava.library.path='/Applications/MATLAB R2018a.app/bin/maci64' -classpath .:'/Applications/MATLAB R2018a.app/extern/engines/java/jar/engine.jar':'./TestCaseCompiler.jar' controller.TestCaseCompiler

jarPath = [fileparts(fileparts(mfilename('fullpath'))) filesep 'TestCaseCompiler.jar'];
if ismac
    libPath = [matlabroot '/bin/maci64'];
    classPath = [matlabroot 'extern/engines/java/jar/engine.jar'];
elseif ispc
    libPath = [matlabroot '\bin\win64'];
    classPath = [matlabroot 'extern\engines\java\jar\engine.jar'];
elseif isunix
    % ??
end

call = sprintf('java -Djava.library.path="%s" -classpath .:"%s":"%s" controller.TestCaseController', ...
    libPath, classPath, jarPath);

[~, ~] = system(call);



end