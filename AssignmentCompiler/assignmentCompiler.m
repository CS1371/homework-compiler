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
% UserName: A character vector or scalar string. The username for the
% server.
%
% Password: A character vector or scalar string. The password for the
% server
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
    parser.addParameter('UserName', '', @(u)(ischar(u) || (isstring(u) && isscalar(u))));
    parser.addParameter('Password', '', @(u)(ischar(u) || (isstring(u) && isscalar(u))));
    parser.addParameter('ClientID', '', @(u)(ischar(u) || (isstring(u) && isscalar(u))));
    parser.addParameter('ClientSecret', '', @(u)(ischar(u) || (isstring(u) && isscalar(u))));
    parser.addParameter('ClientKey', '', @(u)(ischar(u) || (isstring(u) && isscalar(u))));
    parser.parse(varargin{:});
    
    clientId = parser.Results.ClientID;
    clientSecret = parser.Results.ClientSecret;
    clientKey = parser.Results.ClientKey;
    username = parser.Results.UserName;
    password = parser.Results.Password;
    % Steps:
    % 
    % 0. Get settings file
    % 1. Ask for Google Drive Folder
    % 2. Download all folders and convert/download PDF
    % 3. Ask about order
    % 4. Verify each package separately
    % 5. Compile Assignment
    % 6. Verify Assignment as a whole
    % 7. Upload Assignment to Drive
    % 8. Ask for Server User/Pass
    % 9. Upload to Server
    
    % Get Settings File
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
    
    
    