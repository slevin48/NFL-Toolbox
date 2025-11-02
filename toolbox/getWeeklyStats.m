function [weeklyTable, metadata] = getWeeklyStats(week, season, options)
% getWeeklyStats Retrieve weekly NFL statistics as a MATLAB table.
%   weeklyTable = getWeeklyStats(week, season) retrieves the offensive weekly
%   stats for the specified week and season using nfl_data_py via Python.
%
%   [...] = getWeeklyStats(..., StatType="defense") selects the stats type.
%   [...] = getWeeklyStats(..., UseSystemCall=true) invokes a system-level
%   Python call instead of MATLAB's integrated Python engine.
%
%   Outputs:
%       weeklyTable - MATLAB table of weekly statistics (may be empty)
%       metadata    - struct with query metadata (e.g., seasons, filters)

arguments
    week (1,1) double {mustBeFinite, mustBeInteger, mustBePositive}
    season (1,1) double {mustBeFinite, mustBeInteger}
    options.StatType (1,1) string = "offense"
    options.UseSystemCall (1,1) logical = false
    options.PythonCommand (1,1) string = ""
end

validateattributes(week, {'numeric'}, {'scalar', 'integer', '>=', 1, '<=', 23}, mfilename, "week", 1);
validateattributes(season, {'numeric'}, {'scalar', 'integer', '>=', 1999}, mfilename, "season", 2);

params = struct( ...
    "season", int64(season), ...
    "week", int64(week), ...
    "stat_type", char(options.StatType) ...
);

if options.UseSystemCall
    payload = nfl.internal.callSystemWrapper("get_weekly_data", params, "PythonCommand", options.PythonCommand);
else
    payload = nfl.internal.callWrapper("get_weekly_data", params);
end

[weeklyTable, metadata] = nfl.internal.payloadToTable(payload);
end
