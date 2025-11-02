function pythonCmd = detectPythonCommand()
% detectPythonCommand Determine which Python executable to call from MATLAB.

localPython = nfl.internal.localPythonPath();
if strlength(localPython) > 0
    pythonCmd = char(localPython);
    return
end

try
    pe = pyenv;
    if ~isempty(pe.Version) && pe.Status ~= "NotFound"
        pythonCmd = string(pe.Version);
        if isfile(pythonCmd)
            return
        end
    end
catch
    % Fall back to probing PATH below.
end

if ispc
    candidates = ["python", "py"];
else
    candidates = ["python3", "python"];
end

for candidate = candidates
    [status, ~] = system(sprintf('"%s" --version', candidate));
    if status == 0
        pythonCmd = candidate;
        return
    end
end

error("nfl:PythonNotFound", "Unable to locate a Python executable on the system PATH.");
end
