%% authorizeWithGoogle: Authorize with Google Drive
%
% authorizeWithGoogle will perform a one-time authorization to allow the
% autograder to access that user's folders.
%
% R = authorizeWithGoogle(I, S) will authorize with the current user using
% clientID I and client secret S.
%
%%% Remarks
%
% This is primarily used to authenticate with Google so that we can
% programmatically download the solution archive.
%
%%% Exceptions
%
% Like all other networking functions, this throws an
% AUTOGRADER:networking:connectionError exception if something goes wrong.
%
%%% Unit Tests
%
%   R = authorizeWithGoogle();
%
%   % Assuming user says yes, R = '...';
%
%   R = authorizeWithGoogle();
%
%   % Assuming user says no:
%   threw connectionError exception
function token = authorizeWithGoogle(clientId, clientSecret)
    SCOPE = 'https://www.googleapis.com/auth/drive.readonly';
    RESP_TYPE = 'code';
    REDIRECT = 'http://127.0.0.1:9004';
    GRANT_TYPE = 'authorization_code';
    
    URL = ['https://accounts.google.com/o/oauth2/v2/auth?scope=', SCOPE, ...
        '&response_type=', RESP_TYPE, ...
        '&redirect_uri=', REDIRECT, ...
        '&client_id=', clientId];
    web(URL, '-browser');
    % start up server socket
    server = tcpip('0.0.0.0', 9004, 'NetworkRole', 'server');
    % wait for connection
    fopen(server);
    RESPONSE = strjoin({'HTTP/1.1 200 OK', '', getResponse()}, newline);
    % get code
    while server.BytesAvailable == 0
        pause(.5);
    end
    code = char(fread(server, server.BytesAvailable, 'uchar')');
    % write response
    % break into chunks
    % amount left until perfectly 128:
    CHUNK_SIZE = 128;
    amnt = mod(size(RESPONSE, 2), CHUNK_SIZE);
    % add spaces
    RESPONSE = char([RESPONSE, ones(1, CHUNK_SIZE - amnt) * 32]);
    for ind = 1:CHUNK_SIZE:numel(RESPONSE)
        fwrite(server, RESPONSE(ind:(ind + (CHUNK_SIZE - 1))));
    end
    fclose(server);
    % parse the code
    code = strtok(code, newline);
    code = regexp(code, '(?<=^GET [/][?]code[=])[^\s]*', 'match');
    code = code{1};
    % send auth code and get back refresh token
    opts = weboptions();
    opts.RequestMethod = 'POST';
    EXCHANGER = 'https://www.googleapis.com/oauth2/v4/token';
    try
        data = webread(EXCHANGER, 'code', code, 'client_id', clientId, ...
            'client_secret', clientSecret, 'redirect_uri', REDIRECT, ...
            'grant_type', GRANT_TYPE, opts);
    catch reason
        e = MException('AUTOGRADER:networking:connectionError', ...
            'There was an error with the connection');
        e = e.addCause(reason);
        throw(e);
    end
    token = data.refresh_token;
end

function img = getImage()
    fid = fopen([fileparts(mfilename('fullpath')) filesep 'logo.base64'], 'r');
    img = char(fread(fid)');
    fclose(fid);
end

function resp = getResponse()

resp = ['<!DOCTYPE html><html><head><meta charset="utf-8"> ', ...
    '<meta name="viewport" content="width=device-width, initial-scale=1">', ...
    '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.0/css/bootstrap.min.css">', ...
	'<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>', ...
	'<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.0/umd/popper.min.js"></script>', ...
	'<script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.1.0/js/bootstrap.min.js"></script>', ...
	'<link href="https://fonts.googleapis.com/css?family=Open+Sans:300" rel="stylesheet">', ...
	'<title>Success!</title>', ...
	'<style>', ...
    '    body {', ...
	'        background: linear-gradient(to top, #155799, #159957);', ...
	'		 color: white;', ...
	'		 background-size: 1000px 1000px;', ...
	'		 font-family: ''Open Sans'', sans-serif;', ...
	'	 }', ...
    '    img {', ...
    '        width: 50%;', ...
    '        height: 50%', ...
    '    }', ...
	'</style>', ...
'</head>', ...
'<body>', ...
	'<div class="container text-center">'...
		'<h1>Success</h1>', ...
		['<img src="' getImage() '" class="rounded" />'], ...
		'<h2>Successfully Authenticated! Close this window and go back to the autograder...</h2>', ...
	'</div>', ...
'</body>', ...
'</html>'];
end