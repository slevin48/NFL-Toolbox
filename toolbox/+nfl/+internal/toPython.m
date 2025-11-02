function pyValue = toPython(value)
% toPython Prepare MATLAB values for Python keyword arguments.

if isa(value, "string")
    if isscalar(value)
        pyValue = char(value);
    else
        pyValue = cellfun(@char, cellstr(value), "UniformOutput", false);
    end
elseif ischar(value)
    pyValue = value;
elseif isnumeric(value) && isscalar(value)
    if mod(value, 1) == 0
        pyValue = int64(value);
    else
        pyValue = double(value);
    end
elseif iscell(value)
    pyValue = value;
else
    pyValue = value;
end
end

