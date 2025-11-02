function status = setupNFLPyEnv(options)
% setupNFLPyEnv Ensure a Python virtual environment ready for the NFL toolbox.
%   STATUS = setupNFLPyEnv() downloads the uv packaging tool for the current
%   platform (if needed), creates or updates the project's virtual environment
%   under .venv, and installs the pandas and nfl_data_py Python packages.
%
%   setupNFLPyEnv can be customised via name-value options:
%
%       setupNFLPyEnv(EnvironmentRoot="/custom/venv", Requirements=["pandas","nfl_data_py"])
%
%   The returned struct contains success state, detected Python executable, and
%   a log of notable steps.

arguments
    options.EnvironmentRoot (1, 1) string = fullfile(nfl.internal.projectRoot(), ".venv")
    options.Requirements (1, :) string = ["pandas", "nfl_data_py"]
    options.ForceInstallUv (1, 1) logical = false
    options.ForceRecreateVenv (1, 1) logical = false
end

messages = strings(0, 1);
status = struct( ...
    "Success", false, ...
    "PythonExecutable", string.empty, ...
    "Messages", strings(0, 1));

projectRoot = nfl.internal.projectRoot();
uvInstallDir = fullfile(projectRoot, ".uv");

try
    [uvPath, uvMessages] = ensureUvAvailable(uvInstallDir, options.ForceInstallUv);
    messages = [messages; uvMessages]; %#ok<AGROW>

    [pythonExe, venvMessages] = ensureVirtualEnvironment(uvPath, options.EnvironmentRoot, options.ForceRecreateVenv);
    messages = [messages; venvMessages]; %#ok<AGROW>

    if ~isempty(options.Requirements)
        installMessages = installPythonRequirements(uvPath, pythonExe, options.Requirements);
        messages = [messages; installMessages]; %#ok<AGROW>
    end

    status.Success = true;
    status.PythonExecutable = pythonExe;
catch ME
    messages = [messages; string(ME.message); string(ME.getReport())];
end

status.Messages = messages;
end

function [uvPath, messages] = ensureUvAvailable(installDir, forceInstall)
messages = strings(0, 1);
if ~isfolder(installDir)
    mkdir(char(installDir));
end

uvPath = locateUvBinary(installDir);
if ~forceInstall && isfile(uvPath)
    messages(end + 1) = "Reusing existing uv installation at " + string(uvPath);
    return
end

messages(end + 1) = "Fetching uv for the current platform.";
installCmd = buildUvInstallCommand(installDir);
runCommand(installCmd, "uv installer");

uvPath = locateUvBinary(installDir);
if ~isfile(uvPath)
    error("nfl:UvMissing", "uv executable was not found at %s after installation.", uvPath);
end

if ~ispc
    fileattrib(char(uvPath), "+x");
end

messages(end + 1) = "uv installed at " + string(uvPath);
end

function [pythonExe, messages] = ensureVirtualEnvironment(uvPath, envRoot, forceRecreate)
messages = strings(0, 1);
envExists = isfolder(envRoot);

if envExists && forceRecreate
    messages(end + 1) = "Recreating virtual environment at " + string(envRoot);
elseif envExists
    messages(end + 1) = "Virtual environment already present at " + string(envRoot) + ", ensuring metadata is up to date.";
else
    messages(end + 1) = "Creating virtual environment at " + string(envRoot);
end

venvCmd = sprintf('"%s" venv "%s"', uvPath, char(envRoot));
runCommand(venvCmd, "uv venv");

pythonExe = locatePythonExecutable(envRoot);
if pythonExe == ""
    error("nfl:PythonNotFound", "Unable to locate python executable inside %s.", envRoot);
end

messages(end + 1) = "Virtual environment ready with python at " + pythonExe;
end

function messages = installPythonRequirements(uvPath, pythonExe, requirements)
messages = strings(0, 1);
reqList = strjoin(string(requirements), " ");
installCmd = sprintf('"%s" pip install --python "%s" %s', uvPath, pythonExe, char(reqList));
runCommand(installCmd, "uv pip install");

messages(end + 1) = "Installed Python packages: " + strjoin(requirements, ", ");
end

function uvPath = locateUvBinary(installDir)
if ispc
    candidates = [ ...
        fullfile(installDir, "bin", "uv.exe"), ...
        fullfile(installDir, "uv.exe")];
else
    candidates = [ ...
        fullfile(installDir, "bin", "uv"), ...
        fullfile(installDir, "uv")];
end
uvPath = "";
for idx = 1:numel(candidates)
    if isfile(candidates(idx))
        uvPath = char(candidates(idx));
        break
    end
end
end

function pythonExe = locatePythonExecutable(envRoot)
if ispc
    candidates = [ ...
        fullfile(envRoot, "Scripts", "python.exe"), ...
        fullfile(envRoot, "Scripts", "python3.exe")];
else
    candidates = [ ...
        fullfile(envRoot, "bin", "python3"), ...
        fullfile(envRoot, "bin", "python")];
end

pythonExe = "";
for idx = 1:numel(candidates)
    if isfile(candidates(idx))
        pythonExe = string(candidates(idx));
        break
    end
end
end

function cmd = buildUvInstallCommand(installDir)
if ispc
    installDirWin = strrep(installDir, "/", filesep);
    installDirWin = strrep(installDirWin, filesep, "\");
    cmd = sprintf(['powershell -NoProfile -ExecutionPolicy Bypass -Command ', ...
        '"$env:UV_INSTALL_DIR = ''%s''; ', ...
        'iwr -UseBasicParsing https://astral.sh/uv/install.ps1 | iex"'], installDirWin);
else
    installDirChar = char(installDir);
    installDirEscaped = strrep(installDirChar, '"', '\"');
    cmd = sprintf('export UV_INSTALL_DIR="%s"; curl -LsSf https://astral.sh/uv/install.sh | sh', installDirEscaped);
end
end

function runCommand(cmd, label)
if isstring(cmd)
    cmd = char(cmd);
end
[exitCode, commandOut] = system(cmd);
if exitCode ~= 0
    if strlength(commandOut) > 0
        detail = strtrim(commandOut);
    else
        detail = "no additional output.";
    end
    error("nfl:CommandFailed", "%s failed (exit code %d): %s", label, exitCode, detail);
end
end
