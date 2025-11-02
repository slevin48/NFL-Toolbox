function payload = callWrapper(funcName, params)
% callWrapper Helper to invoke the Python wrapper and decode its JSON output.
arguments
    funcName (1,:) char
    params (1,1) struct = struct()
end

nfl.internal.ensurePythonPath();

module = py.importlib.import_module("nfl_data_py_wrapper");

kwargs = {};
fields = fieldnames(params);
if ~isempty(fields)
    kwargs = cell(1, numel(fields) * 2);
    insertIdx = 1;
    for idx = 1:numel(fields)
        key = fields{idx};
        value = params.(key);
        if isempty(value)
            continue
        end
        kwargs{insertIdx} = key;
        kwargs{insertIdx + 1} = nfl.internal.toPython(value);
        insertIdx = insertIdx + 2;
    end
    kwargs = kwargs(1:insertIdx - 1);
end

if isempty(kwargs)
    raw = module.(funcName)();
else
    raw = module.(funcName)(pyargs(kwargs{:}));
end

payload = jsondecode(char(raw));
end

