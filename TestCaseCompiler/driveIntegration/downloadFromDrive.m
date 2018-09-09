%% downloadFromDrive: Download a folder from Google Drive
%
% downloadFromDrive will download a test case folder from google drive, if
% it exists.
%
% downloadFromDrive(P, N, F, T, B) will download from Drive folder F to
% path P, using token T, key K, and function name N. Additionally, it will
% communicate progress with progress bar B.
%
%%% Remarks
%
% downloadFromDrive will use the last part of path P to find the right
% folder; in other words, F should point to the _assignment_ folder, not
% the specific homework, though if F does point to the single problem
% folder, this function is smart enough to compensate. For example, if P is
% "/Users/.../myFunction/", then this function looks for a folder called
% myFunction in google drive that lies at or below F. The closest folder is
% chosen.
%
% If P does not exist, it is created for you. If the folder does not exist
% at or below F, then nothing is downloaded, though the folder is still
% created for you.
function downloadFromDrive(path, name, folder, token, key, progress)
    id = getArchive(folder, name, token, key);
    download(id, path, token, key, progress);
end

function download(folderId, path, token, key, progress)
    progress.Indeterminate = 'off';
    progress.Value = 0;
    progress.Message = 'Downloading Solution Archive from Google Drive';
    workers = downloadFolder(folderId, token, key, path);
    tot = numel(workers);
    while ~all([workers.Read])
        fetchNext(workers);
        progress.Value = min([progress.Value + 1/tot, 1]);
    end
    delete(workers);
end

function workers = downloadFolder(folderId, token, key, path)
    FOLDER_TYPE = 'application/vnd.google-apps.folder';
    INVALID_TYPES = {
    'application/vnd.google-apps.audio', ...
    'application/vnd.google-apps.document', ...
    'application/vnd.google-apps.drawing', ...
    'application/vnd.google-apps.file', ...
    'application/vnd.google-apps.folder', ...
    'application/vnd.google-apps.form', ...
    'application/vnd.google-apps.fusiontable', ...
    'application/vnd.google-apps.map', ...
    'application/vnd.google-apps.photo', ...
    'application/vnd.google-apps.presentation', ...
    'application/vnd.google-apps.script', ...
    'application/vnd.google-apps.site', ...
    'application/vnd.google-apps.spreadsheet', ...
    'application/vnd.google-apps.unknown', ...
    'application/vnd.google-apps.video', ...
    'application/vnd.google-apps.drive-sdk'
    };
    
    if nargin == 3
        origPath = cd(path);
    else
        origPath = pwd;
    end
    cleaner = onCleanup(@()(cd(origPath)));
    % get this folder's information
    folder = getFolder(folderId, token, key);
    % create directory for this root folder and cd to it
    % for all the files inside, download them here
    contents = getFolderContents(folder.id, token, key);
    workers = cell(1, numel(contents));
    for c = numel(contents):-1:1
        content = contents(c);
        if strcmp(content.mimeType, FOLDER_TYPE)
            % folder; call recursively
            mkdir([path filesep content.name]);
            workers{c} = downloadFolder(content.id, token, key, [path filesep content.name]);
        elseif ~any(contains(content.mimeType, INVALID_TYPES))
            % file; download
            workers{c} = parfeval(@downloadFile, 0, content, token, key, path);
        end
    end
    workers = [workers{:}];
    if ~isempty(workers)
        workers([workers.ID] == -1) = [];
    end
end

function downloadFile(file, token, key, path, attemptNum)
    MAX_ATTEMPT_NUM = 10;
    WAIT_TIME = 2;
    if nargin < 5
        attemptNum = 1;
    end
    API = 'https://www.googleapis.com/drive/v3/files/';
    opts = weboptions();
    opts.HeaderFields = {'Authorization', ['Bearer ' token]};
    url = [API file.id '?alt=media&key=' key];
    try
        websave([path filesep file.name], url, opts);
    catch reason
        if attemptNum <= MAX_ATTEMPT_NUM
            pause(WAIT_TIME);
            downloadFile(file, token, key, path, attemptNum + 1);
        else
            e = MException('AUTOGRADER:networking:connectionError', ...
                'Connection was terminated (Are you connected to the internet?');
            e = e.addCause(reason);
            throw(e);
        end
    end
end

function contents = getFolderContents(folderId, token, key)
    API = 'https://www.googleapis.com/drive/v3/files/';
    opts = weboptions();
    opts.HeaderFields = {'Authorization', ['Bearer ' token]};
    try
        contents = webread(API, 'q', ['''' folderId ''' in parents'], 'key', key, opts);
    catch reason
        e = MException('AUTOGRADER:networking:connectionError', ...
            'Connection was terminated (Are you connected to the internet?');
        e = e.addCause(reason);
        throw(e);
    end
    contents = contents.files;
end

function folder = getFolder(folderId, token, key)
    API = 'https://www.googleapis.com/drive/v3/files/';
    opts = weboptions();
    opts.HeaderFields = {'Authorization', ['Bearer ' token]};
    try
        folder = webread([API folderId], 'key', key, opts);
    catch reason
        e = MException('AUTOGRADER:networking:connectionError', ...
            'Connection was terminated (Are you connected to the internet?');
        e = e.addCause(reason);
        throw(e);
    end
end
function id = getArchive(folderId, name, token, key)

    API = 'https://www.googleapis.com/drive/v3/files/';
    opts = weboptions();
    opts.HeaderFields = {'Authorization', ['Bearer ' token]};
    contents = webread(API, 'q', ['''' folderId ''' in parents and name = ''' name ''''], 'key', key, opts);
    if isempty(contents.files)
        % check if we are named correctly
        contents = webread([API folderId], 'key', key, opts);
        if strcmpi(contents.name, name)
            id = folderId;
        else
            throw(MException('TESTCASE:downloadFromDrive:folderNotFound', ...
                'Folder "%s" not found', name));
        end
    else
        id = contents.files(1).id;
    end
end