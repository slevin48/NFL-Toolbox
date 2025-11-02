function pythonPath = localPythonPath()
% localPythonPath Return preferred Python executable within the project.
%   pythonPath is a string with the absolute path to the Python executable
%   inside the project's managed virtual environment (./.venv). If no such
%   interpreter exists, the function returns an empty string.

rootDir = nfl.internal.projectRoot();

candidates = [ ...
    fullfile(rootDir, ".venv", "bin", "python"), ...
    fullfile(rootDir, ".venv", "bin", "python3"), ...
    fullfile(rootDir, ".venv", "Scripts", "python.exe") ...
    ];

pythonPath = string("");
for idx = 1:numel(candidates)
    candidate = candidates(idx);
    if isfile(candidate)
        pythonPath = string(candidate);
        return
    end
end

end

