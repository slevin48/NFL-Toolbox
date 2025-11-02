%% Getting Started with the MATLAB NFL Analytics Toolbox
% Run this live script section-by-section to configure MATLAB, validate the
% Python bridge, and try the high-level helper functions provided by the toolbox.

%% Add Toolbox to the MATLAB Path
% Ensure the toolbox source is available on the MATLAB path so helper functions
% and setup utilities can be located when you run the remaining sections.
addpath(genpath(fullfile(nfl.internal.projectRoot(), "toolbox")));

%% (Optional) Provision or Update the Project Python Environment
% Use setupNFLPyEnv to download the ``uv`` packaging utility, create the
% repository-managed virtual environment at ``.venv``, and install the required
% Python dependencies (`pandas` and `nfl_data_py`).  This step can take a few
% minutes the first time it runs because packages are downloaded from PyPI.
if exist("setupNFLPyEnv", "file")
    try
        setupStatus = setupNFLPyEnv;
        disp(setupStatus.Messages');
    catch ME
        warning("setupNFLPyEnv:Failed", "Environment setup failed:\n%s", ME.getReport());
    end
else
    warning("setupNFLPyEnv:Missing", "setupNFLPyEnv.m not found on the path.");
end

%% Point MATLAB at the Project Virtual Environment
% MATLAB caches the active Python interpreter per session. Terminate any
% existing link, then direct MATLAB to the toolbox virtual environment.
venvPython = fullfile(nfl.internal.projectRoot(), ".venv", "bin", "python");
if ispc
    venvPython = fullfile(nfl.internal.projectRoot(), ".venv", "Scripts", "python.exe");
end
try
    terminate(pyenv);
catch
    % Interpreter was not initialised; nothing to do.
end
pyenv("Version", venvPython);
disp(pyenv);

%% Verify Python Connectivity
% checkNFLDataPySetup confirms that MATLAB can import the wrapper, load
% `nfl_data_py`, and communicate with the Python bridge.
setupReport = checkNFLDataPySetup;
disp(setupReport);
disp(setupReport.Messages');

%% Fetch Weekly Statistics
% Call getWeeklyStats to retrieve offensive player statistics for a week.
% Adjust Season/Week as desired. The result is a MATLAB table.
season = 2023;
week = 5;
weeklyStats = getWeeklyStats(week, season);
head(weeklyStats)

%% Explore Play-by-Play Data
% Retrieve play-by-play records for a given week and team. The metadata output
% includes summary details returned by the Python wrapper.
team = "KC";
[pbp, meta] = getPlayByPlay(season, week, team);
head(pbp)
disp(meta)

%% Visualise Top Performers
% Plot the top passers for the selected week to confirm the plotting utilities
% work in your environment.
statName = "passing_yards";
plotTopPlayers(statName, week, season);

%% Launch the Team Dashboard
% Display the interactive Live Editor dashboard that compares team performance
% metrics across the selected season.
showTeamDashboard(team, season);
