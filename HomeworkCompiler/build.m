%% build: Build the Homework Compiler
%
% build will create the ZIP necessary to install the Homework
% Compiler.
%
% build() will create the installation package, ready to be distributed as
% a ZIP archive.
%
%%% Remarks
%
% This does _not_ do any testing, so make sure to test it before building!
%
%% build: Builds the TestCase Generator
%
% build will build the entire Test Case Generator application
%
% build(V) will build the TestCase Generator to be version V.
%
% build() will do the same as above, but will NOT change the version.
function build(version)
%
%%% Steps
% 1. Copy
% 2. Lint
% 3. Version
% 4. Create mlapp
% 5. Move mlapp
% 6. Delete temp

fprintf(1, '[%s] Starting Build\n', datetime);

%% Copy
fprintf(1, '[%s] Copying Dependencies...', datetime);

workDir = tempname;
mkdir(workDir);
safeDir = cd(workDir);
thisDir = fileparts(mfilename('fullpath'));
buildDir = fullfile(thisDir, 'build');
if isfolder(buildDir)
    rmdir(buildDir, 's');
end
mkdir(buildDir);

clean = onCleanup(@()(cleaner(safeDir, workDir)));

% Dependencies:
% * libs
% * packager
% * verifier
% * interface
% * GoogleDriveIntegration
%
% After copying, remove anything that ends in *.token
dependencies = [dir(thisDir);
                dir(fullfile(thisDir, '..', 'GoogleDriveIntegration'))];
dependencies(strncmp({dependencies.name}, '.', 1)) = [];
dependencies(endsWith({dependencies.name}, '.md', 'IgnoreCase', true)) = [];
dependencies(strcmp({dependencies.name}, 'build.m')) = [];
% save ID, Secret, Key
ind = find(endsWith({dependencies.name}, '.token'), 1);
fid = fopen(fullfile(dependencies(ind).folder, dependencies(ind).name), 'rt');
lines = char(fread(fid)');
fclose(fid);
lines = strsplit(lines, newline);
[clientId, clientSecret, clientKey] = deal(lines{1:3});

dependencies(endsWith({dependencies.name}, '.token')) = [];
dependencies([dependencies.isdir]) = [];

newTokenPath = fullfile(buildDir, 'google.token');
fid = fopen(newTokenPath, 'wt');
fprintf(fid, '%s\n%s\n%s', clientId, clientSecret, clientKey);
fclose(fid);

dependencies(end+1) = dir(fullfile(buildDir, 'google.token'));

for d = 1:numel(dependencies)
    dep = dependencies(d);
    try
        copyfile(fullfile(dep.folder, dep.name), workDir);
    catch
        fprintf(2, '[%s] Failed to copy dependency: %s\n', datetime, dep.name);
        return;
    end
end
fprintf(1, 'Done\n');
%% Lint
fprintf(1, '[%s] Linting source files...', datetime);
files = dir(workDir);
files(startsWith({files.name}, '.')) = [];
files(~endsWith({files.name}, '.m')) = [];
files = join([{files.folder}; {files.name}]', filesep);
[res, paths] = checkcode(files, '-fullpath');
if (isstruct(res) && ~isempty(res)) ...
        || (iscell(res) && ~all(cellfun(@isempty, res)))
    fprintf(2, 'Failed.\nSome source files failed lint test:\n');
    for p = 1:numel(paths)
        if ~isempty(res{p})
            [~, name, ext] = fileparts(paths{p});
            fprintf(2, '\t %s%s\n', name, ext);
        end
    end
    return;
end
fprintf(1, 'Done\n');

%% Version
if nargin == 1
    fprintf(1, '[%s] Writing new version: %s...', datetime, version);
    if version(1) == 'v'
        version(1) = [];
    end
    doc = xmlread(fullfile(thisDir, 'TestCaseCompiler.prj'));
    doc.getElementsByTagName('param.version').item(0).setTextContent(version);
    xmlwrite(fullfile(thisDir, 'TestCaseCompiler.prj'), doc);
    fprintf(1, 'Done\n');
end
%% Configure MLAPP
%{
<configuration file="/path/to/prj" location="/path/to/folder" name="Test Case Compiler" target="target.mlapps" target-name="Package App">
<param.icon>${PROJECT_ROOT}/Test Case Compiler_resources/icon_24.png</param.icon>
<param.icons>
  <file>/path/to/48.png</file>
  <file>/path/to/24.png</file>
  <file>/path/to/16.png</file>
</param.icons>

<param.screenshot>/path/to/screenshot</param.screenshot>

<param.output>/path/to/output/folder</param.output>

<fileset.main>
  <file>/path/to/TestCaseCompiler.m</file>
</fileset.main>


<fileset.depfun>
  <file>/path/to/dependency</file>
  ...
</fileset.depfun>

<build-deliverables>
  <file location="/path/to/parent/of/outputfolder" name="name_of_output_folder" optional="false">/path/to/output/folder</file>
</build-deliverables>
%}
fprintf(1, '[%s] Configuring build...', datetime);
% Read in with xmlread
doc = xmlread(fullfile(thisDir, 'HomeworkCompiler.prj'));

%%% configuration
config = doc.getElementsByTagName('configuration').item(0);
config.setAttribute('file', fullfile(workDir, 'HomeworkCompiler.prj'));
config.setAttribute('location', workDir);

%%% icon
icon = doc.getElementsByTagName('param.icon').item(0);
icon.setTextContent(fullfile(workDir, 'logo24.png'));

%%% icons
icons = doc.getElementsByTagName('param.icons').item(0);

file = doc.createElement('file');
file.setTextContent(fullfile(workDir, 'logo48.png'));
icons.appendChild(file);

file = doc.createElement('file');
file.setTextContent(fullfile(workDir, 'logo24.png'));
icons.appendChild(file);

file = doc.createElement('file');
file.setTextContent(fullfile(workDir, 'logo16.png'));
icons.appendChild(file);

%%% screenshot
screen = doc.getElementsByTagName('param.screenshot').item(0);
screen.setTextContent(fullfile(workDir, 'screenshot.png'));

%%% output
output = doc.getElementsByTagName('param.output').item(0);
output.setTextContent(buildDir);

%%% main
main = doc.getElementsByTagName('fileset.main').item(0);
main = main.getElementsByTagName('file').item(0);
main.setTextContent(fullfile(workDir, 'homeworkCompiler.m'));

%%% depfuns
depfun = doc.getElementsByTagName('fileset.depfun').item(0);
for i = 1:depfun.getLength
    depfun.removeChild(depfun.getFirstChild);
end

% for each dep, add full path
for d = 1:numel(dependencies)
    dep = dependencies(d);
    file = doc.createElement('file');
    file.setTextContent(fullfile(workDir, dep.name));
    depfun.appendChild(file);
end

%%% build deliverables
devs = doc.getElementsByTagName('build-deliverables').item(0);
file = devs.getElementsByTagName('file').item(0);
file.setAttribute('location', fileparts(buildDir));
file.setAttribute('name', 'build');
file.setTextContent(buildDir);
xmlwrite(fullfile(workDir, 'HomeworkCompiler.prj'), doc);
% write to 
fprintf(1, 'Done\n');


%% Package MLAPP
fprintf(1, '[%s] Creating installer...', datetime);
matlab.apputil.package(fullfile(workDir, 'HomeworkCompiler.prj'));
movefile(fullfile(workDir, 'Homework Compiler.mlappinstall'), buildDir);
fprintf(1, 'Done\n');
%% Done
fprintf(1, '[%s] Finished Build\n', datetime);
end

function cleaner(safe, work)
    cd(safe);
    rmdir(work, 's');
end