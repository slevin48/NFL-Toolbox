function ax = plotTopPlayers(metric, week, season, options)
% plotTopPlayers Visualise weekly top performers for a given metric.
%
%   ax = plotTopPlayers("passing_yards", 5, 2023) fetches weekly stats and
%   displays a bar chart of the top 10 players ranked by passing yards.

arguments
    metric (1,1) string
    week (1,1) double {mustBeFinite, mustBeInteger, mustBePositive}
    season (1,1) double {mustBeFinite, mustBeInteger}
    options.TopN (1,1) double {mustBeInteger, mustBePositive} = 10
    options.StatType (1,1) string = "offense"
    options.UseSystemCall (1,1) logical = false
    options.PythonCommand (1,1) string = ""
end

[weeklyTable, ~] = getWeeklyStats(week, season, ...
    StatType=options.StatType, ...
    UseSystemCall=options.UseSystemCall, ...
    PythonCommand=options.PythonCommand);

if isempty(weeklyTable)
    error("nfl:NoData", "No weekly data available for week %d of %d.", week, season);
end

metricName = char(metric);
if ~ismember(metricName, weeklyTable.Properties.VariableNames)
    error("nfl:UnknownMetric", "Metric '%s' not found in weekly stats.", metricName);
end

metricValues = weeklyTable.(metricName);
if ~isnumeric(metricValues)
    error("nfl:NonNumericMetric", "Metric '%s' must be numeric to plot.", metricName);
end

[~, sortIdx] = sort(metricValues, "descend", "MissingPlacement", "last");
topCount = min(options.TopN, height(weeklyTable));
topRows = weeklyTable(sortIdx(1:topCount), :);

nameColumnCandidates = ["player_display_name", "player_name", "recent_team", "posteam"];
labelVar = "";
for candidate = nameColumnCandidates
    if ismember(candidate, topRows.Properties.VariableNames)
        labelVar = candidate;
        break
    end
end

if labelVar == ""
    labels = string(1:topCount);
else
    labels = string(topRows.(labelVar));
end

values = double(topRows.(metricName));

figureHandle = figure("Name", sprintf("Top %d Players - %s (Week %d, %d)", ...
    topCount, metricName, week, season));
ax = axes(figureHandle);
barh(ax, flip(values));
ax.YTick = 1:topCount;
ax.YTickLabel = flip(labels);
ax.YDir = "reverse";
xlabel(ax, metricName, "Interpreter", "none");
ylabel(ax, "Player / Team");
title(ax, sprintf("Top %d %s - Week %d (%d)", topCount, metricName, week, season), ...
    "Interpreter", "none");
grid(ax, "on");

end

