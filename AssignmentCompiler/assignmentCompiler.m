%% assignmentCompiler: Compile a given assignment and upload it
%
% assignmentCompiler will download, parse, verify, package, and distribute
% a given homework assignment.
%
% assignmentCompiler() will begin the process by asking for a folder from
% Google Drive, then asking for an order. assignmentCompiler will then do
% the rest of the necessary operations
%
%%% Remarks
%
% assignmentCompiler uses the results of testCaseCompiler. It is required
% that all packages within the chosen Google Drive folder be of the
% testCaseCompiler format. For more information on this format, look at the
% documentation for testCaseCompiler
function assignmentCompiler