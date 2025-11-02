function ensurePythonPath()
% ensurePythonPath Adds the project's Python directory to sys.path once.

pythonDir = fullfile(nfl.internal.projectRoot(), "toolbox", "resources", "python");
if ~isfolder(pythonDir)
    error("nfl:MissingPythonDir", "Expected Python directory at %s", pythonDir);
end

sysPathPy = py.sys.path;
sysPath = cell(py.list(sysPathPy));
sysPathChars = cellfun(@char, sysPath, "UniformOutput", false);
if ~any(strcmp(sysPathChars, pythonDir))
    sysPathPy.insert(int32(0), pythonDir);
    py.importlib.invalidate_caches();
end

persistent pathAdded
pathAdded = true; %#ok<NASGU>
end
