function payload = callSystemWrapper(funcName, params, options)
% callSystemWrapper Invoke the Python wrapper via a system command.
arguments
    funcName (1,:) char
    params (1,1) struct = struct()
    options.PythonCommand (1,1) string = ""
end

pythonCmd = options.PythonCommand;
if strlength(pythonCmd) == 0
    pythonCmd = nfl.internal.detectPythonCommand();
end

scriptPath = fullfile(nfl.internal.projectRoot(), "toolbox", "resources", "python", "nfl_data_py_wrapper.py");
if ~isfile(scriptPath)
    error("nfl:MissingWrapperScript", "Expected Python wrapper at %s", scriptPath);
end

jsonParams = jsonencode(params);
jsonParams = strrep(jsonParams, "'", "''"); % escape single quotes for shell

command = sprintf('"%s" "%s" %s --params ''%s''', pythonCmd, scriptPath, funcName, jsonParams);
[status, output] = system(command);
if status ~= 0
    error("nfl:SystemCallFailed", ...
          "Python command failed with status %d. Output:\n%s", status, output);
end

payload = jsondecode(strtrim(output));
end
