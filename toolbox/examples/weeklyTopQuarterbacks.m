%% Weekly Top Quarterbacks by Passing Yards
% This live script demonstrates how to retrieve weekly statistics with
% getWeeklyStats, filter for quarterbacks, and visualise the top performers.

%% Add Toolbox to the MATLAB Path
addpath(genpath(fullfile(nfl.internal.projectRoot(), "toolbox")));

%% Validate Python Connectivity (Optional)
% Quickly confirm the Python bridge is ready before running the analytics.
try
    status = checkNFLDataPySetup;
    disp(status.Messages');
catch ME
    warning("weeklyTopQuarterbacks:Setup", ...
        "Python bridge check failed:\n%s", ME.getReport());
end

%% Configure Target Week and Season
season = 2023;
week = 5;

%% Retrieve Weekly Statistics
stats = getWeeklyStats(week, season);

%% Filter for Quarterbacks and Select Metrics
posValues = string(stats.position);
qbStats = stats(posValues == "QB", :);
requiredVars = ["player_display_name", "team", "passing_yards"];
if ~all(ismember(requiredVars, qbStats.Properties.VariableNames))
    error("weeklyTopQuarterbacks:MissingVars", ...
        "Expected variables %s in the weekly stats table.", strjoin(requiredVars, ", "));
end
qbStats = qbStats(:, requiredVars);

%% Rank and Display the Top 10 Quarterbacks
qbStats = sortrows(qbStats, "passing_yards", "descend");
topCount = min(10, height(qbStats));
topQBs = qbStats(1:topCount, :);
disp(topQBs)

%% Visualise Passing Yards with a Horizontal Bar Chart
figure("Name", sprintf("Top %d Quarterbacks - Week %d, %d", topCount, week, season));
barh(topQBs.passing_yards);
set(gca, "YTickLabel", topQBs.player_display_name, "YTick", 1:topCount);
xlabel("Passing Yards");
title(sprintf("Week %d, %d - Top %d Quarterbacks by Passing Yards", week, season, topCount));
grid on;
