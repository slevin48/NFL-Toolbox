function fig = showTeamDashboard(team, season, options)
% showTeamDashboard Create an at-a-glance visual dashboard for a team/season.
%
%   fig = showTeamDashboard("KC", 2023) aggregates several nfl_data_py
%   datasets to highlight weekly production, win totals, and roster metrics.

arguments
    team (1,1) string
    season (1,1) double {mustBeFinite, mustBeInteger}
    options.StatType (1,1) string = "offense"
    options.UseSystemCall (1,1) logical = false
    options.PythonCommand (1,1) string = ""
end

team = upper(strtrim(team));

queryFun = @(name, params) fetchPayload(name, params, options.UseSystemCall, options.PythonCommand);

weeklyPayload = queryFun("get_weekly_data", struct( ...
    "season", int64(season), ...
    "stat_type", char(options.StatType)));
[weeklyTable, ~] = nfl.internal.payloadToTable(weeklyPayload);

seasonPayload = queryFun("get_seasonal_data", struct( ...
    "season", int64(season), ...
    "stat_type", "team", ...
    "season_type", "REG"));
[seasonTable, ~] = nfl.internal.payloadToTable(seasonPayload);

winPayload = queryFun("get_win_totals", struct("season", int64(season)));
[winTable, ~] = nfl.internal.payloadToTable(winPayload);

rosterPayload = queryFun("get_rosters", struct("season", int64(season)));
[rosterTable, ~] = nfl.internal.payloadToTable(rosterPayload);

weeklyTeam = filterByTeam(weeklyTable, team);
rosterTeam = filterByTeam(rosterTable, team);

fig = figure("Name", sprintf("%s %d Dashboard", team, season));
tiledlayout(fig, 2, 2, "Padding", "compact", "TileSpacing", "tight");

% Tile 1: Weekly production breakdown
nexttile;
plotWeeklyProduction(weeklyTeam);

% Tile 2: Win totals comparison
nexttile;
plotWinTotals(winTable, seasonTable, team, season);

% Tile 3: Roster summary
nexttile;
plotRosterSummary(rosterTeam, team);

% Tile 4: Top performers text summary
nexttile;
plotTopPerformersSummary(weeklyTeam, team);

sgtitle(fig, sprintf("%s %d Team Dashboard", team, season), "FontWeight", "bold");
end

function payload = fetchPayload(functionName, params, useSystem, pythonCommand)
if useSystem
    payload = nfl.internal.callSystemWrapper(functionName, params, "PythonCommand", pythonCommand);
else
    payload = nfl.internal.callWrapper(functionName, params);
end
end

function tbl = filterByTeam(inputTable, team)
if isempty(inputTable)
    tbl = inputTable;
    return
end

teamColumns = ["recent_team", "team", "abbr", "team_abbr", "club_code"];
mask = false(height(inputTable), 1);
for col = teamColumns
    if ismember(col, inputTable.Properties.VariableNames)
        values = string(inputTable.(col));
        mask = mask | strcmpi(values, team);
    end
end
tbl = inputTable(mask, :);
end

function plotWeeklyProduction(weeklyTeam)
if isempty(weeklyTeam)
    title("Weekly Production");
    text(0.5, 0.5, "No weekly data", "HorizontalAlignment", "center");
    axis off;
    return
end

metricCandidates = ["passing_yards", "rushing_yards", "receiving_yards"];
metricCandidates = metricCandidates(ismember(metricCandidates, weeklyTeam.Properties.VariableNames));
if isempty(metricCandidates)
    title("Weekly Production");
    text(0.5, 0.5, "Metrics unavailable", "HorizontalAlignment", "center");
    axis off;
    return
end

summary = groupsummary(weeklyTeam, "week", "sum", metricCandidates);
weeks = summary.week;
dataMatrix = zeros(height(summary), numel(metricCandidates));
for idx = 1:numel(metricCandidates)
    colName = "sum_" + metricCandidates(idx);
    dataMatrix(:, idx) = double(summary.(colName));
end

area(weeks, dataMatrix, "LineStyle", "none");
legend(strrep(metricCandidates, "_", " "), "Location", "northwest");
title("Weekly Yardage Breakdown");
xlabel("Week");
ylabel("Yards");
grid on;
end

function plotWinTotals(winTable, seasonTable, team, season)
projected = NaN;
actual = NaN;

if ~isempty(winTable)
    row = selectTeamRow(winTable, team, season, ["team", "team_abbr", "team_short"]);
    if ~isempty(row)
        projected = firstNumeric(row, ["win_total", "projected_wins", "team_win_total"]);
        actual = firstNumeric(row, ["wins", "team_wins", "actual_wins", "wins_actual"]);
    end
end

if isnan(actual) && ~isempty(seasonTable)
    row = selectTeamRow(seasonTable, team, season, ["team", "team_name", "team_abbr", "abbr"]);
    if ~isempty(row)
        actual = firstNumeric(row, ["wins", "team_wins", "total_wins"]);
    end
end

if all(isnan([projected, actual]))
    title("Win Totals Comparison");
    text(0.5, 0.5, "Win data unavailable", "HorizontalAlignment", "center");
    axis off;
    return
end

values = [projected, actual];
labels = ["Projected", "Actual"];
bar(values);
set(gca, "XTickLabel", labels);
ylabel("Wins");
title("Projected vs Actual Wins");
ylim([0, max(values(~isnan(values)))*1.2 + eps]);
grid on;
end

function row = selectTeamRow(tableData, team, season, teamColumns)
if isempty(tableData)
    row = table();
    return
end

mask = false(height(tableData), 1);
for col = teamColumns
    if ismember(col, tableData.Properties.VariableNames)
        mask = mask | strcmpi(string(tableData.(col)), team);
    end
end

if ismember("season", tableData.Properties.VariableNames)
    mask = mask & tableData.season == season;
elseif ismember("schedule_season", tableData.Properties.VariableNames)
    mask = mask & tableData.schedule_season == season;
end

row = tableData(mask, :);
if height(row) > 1
    row = row(1, :);
end
end

function value = firstNumeric(row, candidates)
value = NaN;
for col = candidates
    if ismember(col, row.Properties.VariableNames)
        data = row.(col);
        if isnumeric(data)
            value = double(data(1));
            if ~isnan(value)
                return
            end
        end
    end
end
end

function plotRosterSummary(rosterTeam, team)
if isempty(rosterTeam)
    title("Roster Summary");
    text(0.5, 0.5, "Roster data unavailable", "HorizontalAlignment", "center");
    axis off;
    return
end

age = NaN;
heightIn = NaN;
weightLb = NaN;

if ismember("age", rosterTeam.Properties.VariableNames)
    age = mean(rosterTeam.age, "omitnan");
end

heightCandidates = ["height_in", "height_inches", "height"];
for col = heightCandidates
    if ismember(col, rosterTeam.Properties.VariableNames)
        heightIn = mean(rosterTeam.(col), "omitnan");
        if ~isnan(heightIn)
            break
        end
    end
end

if ismember("weight", rosterTeam.Properties.VariableNames)
    weightLb = mean(rosterTeam.weight, "omitnan");
end

metrics = [age, heightIn, weightLb];
labels = ["Avg Age", "Avg Height (in)", "Avg Weight (lb)"];
valid = ~isnan(metrics);

if ~any(valid)
    title("Roster Summary");
    text(0.5, 0.5, "Roster metrics unavailable", "HorizontalAlignment", "center");
    axis off;
    return
end

bar(metrics(valid));
set(gca, "XTickLabel", labels(valid));
title(sprintf("%s Roster Profile", team));
grid on;
end

function plotTopPerformersSummary(weeklyTeam, team)
axis off;
title("Top Performers");
if isempty(weeklyTeam)
    text(0.5, 0.5, "Weekly data unavailable", "HorizontalAlignment", "center");
    return
end

nameColumn = "";
for candidate = ["player_display_name", "player_name"]
    if ismember(candidate, weeklyTeam.Properties.VariableNames)
        nameColumn = candidate;
        break
    end
end

if nameColumn == ""
    text(0.5, 0.5, "Player names unavailable", "HorizontalAlignment", "center");
    return
end

metricPairs = {
    "Passing Yards", "passing_yards";
    "Rushing Yards", "rushing_yards";
    "Receiving Yards", "receiving_yards"
    };

lines = strings(0, 1);
for idx = 1:size(metricPairs, 1)
    label = metricPairs{idx, 1};
    column = metricPairs{idx, 2};
    if ~ismember(column, weeklyTeam.Properties.VariableNames)
        continue
    end
    totals = groupsummary(weeklyTeam, nameColumn, "sum", column);
    totals = sortrows(totals, "sum_" + column, "descend");
    topCount = min(3, height(totals));
    if topCount == 0
        continue
    end
    names = string(totals.(nameColumn)(1:topCount));
    values = double(totals.("sum_" + column)(1:topCount));
    entries = names + " - " + string(values) + " " + label;
    lines = [lines; label + ":"; "  " + entries];
end

if isempty(lines)
    text(0.5, 0.5, "Per-metric leaders unavailable", "HorizontalAlignment", "center");
else
    text(0, 1, strjoin(lines, newline), "VerticalAlignment", "top");
end
end
