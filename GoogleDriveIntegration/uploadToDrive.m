%% uploadToDrive: Uplaod a folder to Google Drive
%
% uploadToDrive will upload a given folder or file to the specified address
% in the user's google drive.
%
% uploadToDrive(R, P, T, K) will upload file or folder path P to root drive
% folder R, using token T and key K.
%
%%% Remarks
%
% uploadToDrive will create the named folder, if necessary; if the folder
% already exists, that folder is trashed, and a new one is created.
function uploadToDrive(root, path, token, key)

% Steps:
%
% 1. See if folder already exists; if so, trash
% 2. Upload
