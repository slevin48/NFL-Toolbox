function status = checkNFLDataPySetup(options)
% checkNFLDataPySetup Verify Python integration and nfl_data_py availability.
%
%   status = checkNFLDataPySetup() inspects the active Python environment and
%   reports whether nfl_data_py and the wrapper module can be imported.
%
%   status = checkNFLDataPySetup(PythonExecutable="/usr/bin/python3") forces
%   MATLAB to use a specific Python interpreter before performing checks.
%
%   The returned status struct contains fields:
%       PythonVersion        - Path to the Python executable in use
%       PythonLoaded         - True if MATLAB successfully initialised Python
%       HasNflDataPy         - True if nfl_data_py import succeeded
%       NflDataPyVersion     - Version string when available
%       WrapperResponsive    - True if the wrapper's check_module returned JSON
%       Messages             - Diagnostic strings (cell array)

arguments
    options.PythonExecutable (1,1) string = ""
end

messages = strings(0, 1);

selectedPython = options.PythonExecutable;
autoSelected = false;

if strlength(selectedPython) == 0
    localPython = nfl.internal.localPythonPath();
    if strlength(localPython) > 0
        selectedPython = localPython;
        autoSelected = true;
    end
end

try
    pe = pyenv;
    if strlength(selectedPython) > 0
        currentVersion = string(pe.Version);
        if pe.Status == "NotLoaded"
            pe = pyenv("Version", char(selectedPython));
            if autoSelected
                messages(end + 1) = "Auto-selected project virtual environment Python executable.";
            else
                messages(end + 1) = "Configured custom Python executable.";
            end
        elseif currentVersion ~= selectedPython
            messages(end + 1) = "Python already initialised with: " + currentVersion;
        else
            if autoSelected
                messages(end + 1) = "Project virtual environment Python already active.";
            else
                messages(end + 1) = "Custom Python executable already active.";
            end
        end
    end
catch err
    status = struct( ...
        "PythonVersion", char(selectedPython), ...
        "PythonLoaded", false, ...
        "HasNflDataPy", false, ...
        "NflDataPyVersion", "", ...
        "WrapperResponsive", false, ...
        "Messages", ["pyenv failure: " + err.message] ...
    );
    return
end

status = struct( ...
    "PythonVersion", string(pe.Version), ...
    "PythonLoaded", pe.Status ~= "NotLoaded", ...
    "HasNflDataPy", false, ...
    "NflDataPyVersion", "", ...
    "WrapperResponsive", false, ...
    "Messages", [] ...
);

try
    nfl.internal.ensurePythonPath();
    messages(end + 1) = "Python path updated with project wrapper.";
catch err
    messages(end + 1) = "Failed to update Python path: " + err.message;
end

try
    nflModule = py.importlib.import_module("nfl_data_py");
    status.HasNflDataPy = true;
    if py.hasattr(nflModule, "__version__")
        versionObj = py.getattr(nflModule, "__version__");
        status.NflDataPyVersion = string(versionObj);
    else
        status.NflDataPyVersion = "";
    end
    messages(end + 1) = "nfl_data_py import successful.";
catch err
    messages(end + 1) = "nfl_data_py import failed: " + err.message;
end

try
    wrapperModule = py.importlib.import_module("nfl_data_py_wrapper");
    raw = wrapperModule.check_module();
    payload = jsondecode(char(raw));
    if isstruct(payload) && isfield(payload, "module")
        status.WrapperResponsive = true;
        messages(end + 1) = "Wrapper responded successfully.";
    else
        messages(end + 1) = "Wrapper response invalid.";
    end
catch err
    messages(end + 1) = "Wrapper check failed: " + err.message;
end

status.Messages = messages;
end
