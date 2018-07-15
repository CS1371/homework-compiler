%% refresh2access: Convert a refresh token to an Access token
%
% This will convert a given refresh token to it's corresponding access
% token.
%
% A = refresh2access(R, I, S) will use the refresh token R, the clientID I,
% and the client secret S.
%
%%% Remarks
%
% This is used exclusively with Google and it's API
%
%%% Exceptions
%
% As with all other networking functions, an
% AUTOGRADER:networking:connectionError exception is thrown if the
% connection is interrupted
%
%%% Unit Tests
%
%   R = '..'; % valid refresh
%   A = refresh2access(R);
%
%   A -> Valid Access token
function access = refresh2access(refresh, clientId, clientSecret)
    GRANT_TYPE = 'refresh_token';
    API = 'https://www.googleapis.com/oauth2/v4/token';
    
    apiOpts = weboptions();
    apiOpts.RequestMethod = 'POST';
    try
        data = webread(API, 'client_id', clientId, ...
            'client_secret', clientSecret, ...
            'refresh_token', refresh, ...
            'grant_type', GRANT_TYPE, ...
            apiOpts);
    catch reason
        e = MException('AUTOGRADER:networking:connectionError', ...
            'An error was encountered during the transfer');
        e = e.addCause(reason);
        e.throw();
    end
    access = data.access_token;
end