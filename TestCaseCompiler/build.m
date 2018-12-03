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
dependencies = [dir(fullfile(thisDir, 'libs'));
                dir(fullfile(thisDir, 'packager'));
                dir(fullfile(thisDir, 'verifier'));
                dir(fullfile(thisDir, 'interface'));
                dir(fullfile(thisDir, '..', 'GoogleDriveIntegration'));
                dir(thisDir)];
dependencies(strncmp({dependencies.name}, '.', 1)) = [];
dependencies(endsWith({dependencies.name}, '.token')) = [];
dependencies([dependencies.isdir]) = [];

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
doc = xmlread(fullfile(thisDir, 'TestCaseCompiler.prj'));

%%% configuration
config = doc.getElementsByTagName('configuration').item(0);
config.setAttribute('file', fullfile(workDir, 'TestCaseCompiler.prj'));
config.setAttribute('location', workDir);

%%% icon
icon = doc.getElementsByTagName('param.icon').item(0);
icon.setTextContent(fullfile(workDir, 'logo24.png'));

%%% icons
icons = doc.getElementsByTagName('param.icons').item(0);
icons = icons.getElementsByTagName('file');
icons.item(0).setTextContent(fullfile(workDir, 'logo48.png'));
icons.item(1).setTextContent(fullfile(workDir, 'logo24.png'));
icons.item(2).setTextContent(fullfile(workDir, 'logo16.png'));

%%% screenshot
screen = doc.getElementsByTagName('param.screenshot').item(0);
screen.setTextContent(fullfile(workDir, 'screenshot.png'));

%%% output
output = doc.getElementsByTagName('param.output').item(0);
output.setTextContent(buildDir);

%%% main
main = doc.getElementsByTagName('fileset.main').item(0);
main = main.getElementsByTagName('file').item(0);
main.setTextContent(fullfile(workDir, 'TestCaseCompiler.m'));

%%% depfuns
depfun = doc.getElementsByTagName('fileset.depfun').item(0);
for i = 1:depfun.getLength
    depfun.removeChild(depfun.getFirstChild);
end

% for each dep, add full path
for d = 1:numel(dependencies)
    dep = dependencies(d);
    file = doc.createElement('file');
    file.setTextContent(fullfile(dep.folder, dep.name));
    depfun.appendChild(file);
end

%%% build deliverables
devs = doc.getElementsByTagName('build-deliverables').item(0);
file = devs.getElementsByTagName('file').item(0);
file.setAttribute('location', fileparts(buildDir));
file.setAttribute('name', 'build');
file.setTextContent(buildDir);
xmlwrite(fullfile(workDir, 'TestCaseCompiler.prj'), doc);
% write to 
fprintf(1, 'Done\n');


%% Package MLAPP
fprintf(1, '[%s] Creating installer...', datetime);
matlab.apputil.package(fullfile(workDir, 'TestCaseCompiler.prj'));
movefile(fullfile(workDir, 'Test Case Compiler.mlappinstall'), buildDir);
fprintf(1, 'Done\n');
%% Done
fprintf(1, '[%s] Finished Build\n', datetime);
end

function cleaner(safe, work)
    cd(safe);
    rmdir(work, 's');
end