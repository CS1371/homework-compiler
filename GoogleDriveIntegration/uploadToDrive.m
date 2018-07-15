%% uploadToDrive: Upload a folder to Google Drive
%
% uploadToDrive will create necessary folders and upload all files, keeping
% their structure intact.
%
% uploadToDrive(P, F, T, K, B) will upload folder path P to Drive
% location F, using token T and Drive Key K. It will update progress bar B.
%
%%% Remarks
%
% uploadToDrive will create a folder in F with the name of the last folder
% in path P. So if P is /Users/.../myFunction/, then it will create a
% single folder in F called myFunction. If myFunction already exists, it
% will be overwritten. However, due to the way google drive manages
% folders, it's saved as a revision instead.
function uploadToDrive(path, folder, token, key, progress)
    progress.Message = 'Uploading to Google Drive';
    progress.Indeterminate = 'on';
    [~, funName, ~] = fileparts(path);
    newId = setupFolder(folder, funName, token, key);
    
    % for each file in folder, upload. For each FOLDER, create it and
    % repeat.
    uploadFolder(path, newId, token);
end

function uploadFolder(path, newId, token)
    folders = dir(path);
    folders(~[folders.isdir]) = [];
    folders(strncmp({folders.name}, '.', 1)) = [];
    % for each folder, rinse and repeat
    for f = 1:numel(folders)
        % create the folder
        subId = createFolder(newId, folders(f).name, token);
        uploadFolder([folders(f).folder filesep folders(f).name], subId, token);
    end
    
    % for each FILE, upload. for each FOLDER, create it, increment the
    % path, and pass in newId
    attachments = dir(path);
    attachments([attachments.isdir]) = [];
    attachments = join([{attachments.folder}; {attachments.name}]', filesep);
    for a = numel(attachments):-1:1
        uploadFile(attachments{a}, newId, token);
    end
end

function uploadFile(path, newId, token)
    UPLOAD_API = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=media';
    DRIVE_API = 'https://www.googleapis.com/drive/v3/files/';
    fid = fopen(path, 'r');
    bytes = uint8(fread(fid))';
    fclose(fid);

    % upload the file
    request = matlab.net.http.RequestMessage;
    auth = matlab.net.http.HeaderField;
    auth.Name = 'Authorization';
    auth.Value  = ['Bearer ' token];
    contentType = matlab.net.http.HeaderField;
    contentType.Name = 'Content-Type';
    contentLength = matlab.net.http.HeaderField;
    contentLength.Name = 'Content-Length';
    contentLength.Value = num2str(length(bytes));

    request.Method = 'POST';
    request.Header = [auth contentType contentLength];
    body = matlab.net.http.MessageBody;
    body.Payload = bytes;
    request.Body = body;
    file = request.send(UPLOAD_API);
    id = file.Body.Data.id;

    % Renaming the File
    request = matlab.net.http.RequestMessage;
    request.Method= 'PATCH';
    contentType = matlab.net.http.HeaderField;
    contentType.Name = 'Content-Type';
    contentType.Value = 'application/json';
    request.Header = [auth contentType];

    body = matlab.net.http.MessageBody;
    [~, name, ext] = fileparts(path);
    data.name = [name ext];
    body.Data = data;
    request.Body = body;
    request.send([DRIVE_API id '?addParents=' newId '&removeParents=root']);
end

function newId = createFolder(parent, folderName, token)
    API = 'https://www.googleapis.com/drive/v3/files/';
    TYPE = 'application/vnd.google-apps.folder';
    opts = weboptions();
    opts.HeaderFields = {'Authorization', ['Bearer ' token]};
    opts.ContentType = 'json';
    opts.RequestMethod = 'POST';
   
    data.name = folderName;
    data.parents = {parent};
    data.mimeType  = TYPE;
    newId = webwrite(API, data, opts);
    newId = newId.id;
end

function newId = setupFolder(folderId, name, token, key)
    API = 'https://www.googleapis.com/drive/v3/files/';
    opts = weboptions();
    opts.HeaderFields = {'Authorization', ['Bearer ' token]};
    try
        contents = webread(API, 'q', ['''' folderId ''' in parents and name = ''' name ''''], 'key', key, opts);
    catch reason
        e = MException('AUTOGRADER:networking:connectionError', ...
            'Connection was terminated (Are you connected to the internet?');
        e = e.addCause(reason);
        throw(e);
    end
    if isempty(contents.files)
        newId = createFolder(folderId, name, token);
    else
        newId = contents.files(1).id;
    end
end