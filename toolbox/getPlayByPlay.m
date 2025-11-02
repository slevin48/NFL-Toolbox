function [pbpTable, metadata] = getPlayByPlay(season, week, team, options)
% getPlayByPlay Retrieve play-by-play data for a given season/week/team.
%
%   pbp = getPlayByPlay(season, week) returns play-by-play rows for the
%   specified week of the season.
%
%   pbp = getPlayByPlay(season, week, team) filters to games involving TEAM.
%
%   Additional options:
%       UseSystemCall  - true to call Python via system() instead of py.*
%       PythonCommand  - custom python executable when UseSystemCall=true
%
%   Outputs:
%       pbpTable - MATLAB table of play-by-play events
%       metadata - struct describing the query (source, filters, seasons)

arguments
    season (1,1) double {mustBeFinite, mustBeInteger}
    week double = []
    team string = ""
    options.UseSystemCall (1,1) logical = false
    options.PythonCommand (1,1) string = ""
end

validateattributes(season, {'numeric'}, {'scalar', 'integer', '>=', 1999}, mfilename, "season", 1);
if ~isempty(week)
    validateattributes(week, {'numeric'}, {'scalar', 'integer', '>=', 1, '<=', 23}, mfilename, "week", 2);
end

params = struct("season", int64(season));
if ~isempty(week)
    params.week = int64(week);
end

team = upper(strtrim(team));
if strlength(team) > 0
    params.team = char(team);
end

if options.UseSystemCall
    payload = nfl.internal.callSystemWrapper("get_play_by_play", params, "PythonCommand", options.PythonCommand);
else
    payload = nfl.internal.callWrapper("get_play_by_play", params);
end

[pbpTable, metadata] = nfl.internal.payloadToTable(payload);
end
