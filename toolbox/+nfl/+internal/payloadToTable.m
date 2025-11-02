function [tbl, meta] = payloadToTable(payload)
% payloadToTable Convert decoded JSON payload into a MATLAB table & metadata.
arguments
    payload struct
end

if ~isfield(payload, "data")
    error("nfl:InvalidPayload", "Expected payload struct to contain a 'data' field.");
end

if isempty(payload.data)
    tbl = table();
else
    dataStruct = payload.data;
    if ~isstruct(dataStruct)
        error("nfl:InvalidPayload", "Expected payload.data to decode into a struct array.");
    end
    try
        tbl = struct2table(dataStruct, "AsArray", true);
    catch
        % Fallback: convert to struct array with consistent fields.
        dataStruct = orderfields(dataStruct);
        tbl = struct2table(dataStruct, "AsArray", true);
    end
end

if isfield(payload, "meta")
    meta = payload.meta;
else
    meta = struct();
end
end

