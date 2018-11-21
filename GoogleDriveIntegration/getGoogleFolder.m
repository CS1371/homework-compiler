%% getGoogleFolder: Interactively asks the user for a Google Folder
%
% getGoogleFolder will block and wait until the user successfully selects a
% Google Drive Folder.
%
% getGoogleFolder() will launch the GoogleDriveBrowser mlapp
%
%%% Remarks
%
% This function is part of the broader effort to move as much purely MATLAB
% code into MATLAB.
%
function fid = getGoogleFolder()
    % launch browser; block
    browser = GoogleDriveBrowser();
    uiwait(browser.UIFigure);
    % when we finish, just get the selectedId:
    if isvalid(browser)
        fid = browser.selectedId;
    else
        fid = '';
    end
    if isvalid(browser) && isvalid(browser.UIFigure)
        close(browser.UIFigure);
    end
end
        