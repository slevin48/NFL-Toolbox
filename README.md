# MATLAB NFL Analytics Toolbox [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=slevin48/NFL-Toolbox)

This project provides a MATLAB-first interface to the open-source
[`nfl_data_py`](https://pypi.org/project/nfl-data-py/) library.  It delivers
ready-to-use functions for importing public NFL datasets, exploring player and
team performance, and visualising trends directly inside MATLAB.

## Features

- **Python bridge** ??? Lightweight Python wrapper (`toolbox/python/nfl_data_py_wrapper.py`)
  that exposes core `nfl_data_py` queries with JSON serialisation.
- **MATLAB helpers** ??? High-level MATLAB functions for weekly statistics,
  play-by-play exploration, top-performer plots, and team dashboards. Weekly
  stats default to offensive positions; pass `StatType` (e.g., `"defense"`,
  `"kicking"`, or `"all"`) to retune the position filters.
- **Dual execution modes** ??? Choose MATLAB's built-in `py.*` interface or a
  system-level Python call for environments where MATLAB's Python engine is not
  configured.
- **Environment check** ??? `checkNFLDataPySetup` quickly validates your Python
  interpreter, module availability, and wrapper connectivity.

## Directory layout

```
toolbox/
  checkNFLDataPySetup.m
  toolboxContents.m
  getPlayByPlay.m
  getWeeklyStats.m
  plotTopPlayers.m
  showTeamDashboard.m
  doc/
    GettingStarted.m
  examples/
    weeklyTopQuarterbacks.m
  python/
    nfl_data_py_wrapper.py
  +nfl/+internal/
    callSystemWrapper.m
    callWrapper.m
    detectPythonCommand.m
    ensurePythonPath.m
    payloadToTable.m
    projectRoot.m
    toPython.m
+scripts/
  packageToolbox.m
  runTests.m
tests/
  testProjectLayout.m
```

## Getting started

0. **Open in MATLAB Online**

   Follow instructions from blog post on [pip & uv in MATLAB Online](https://blogs.mathworks.com/deep-learning/2025/09/17/pip-uv-in-matlab-online/):
   ```matlab
   % Retrieve pip from PyPA
    websave('/tmp/get-pip.py','https://bootstrap.pypa.io/get-pip.py');
    % Install pip
    system('python /tmp/get-pip.py');
    % Install dependencies
    system('python -m pip install -q pandas nfl_data_py');
    ```
    If you are running on your desktop make sure to have a python environment with pandas and nfl_data_py installed.

1. **Confirm Python setup**

   ```matlab
   status = checkNFLDataPySetup;
   disp(status)
   ```

   If MATLAB is not linked to the Python environment that contains
   `nfl_data_py`, specify it explicitly:

   ```matlab
   status = checkNFLDataPySetup(PythonExecutable="/path/to/python");
   ```

   When no interpreter is specified, the toolbox automatically attempts to use
   the repository's managed environment at `.venv/bin/python` (or the platform
   equivalent) before falling back to the system configuration.

2. **Call high-level MATLAB functions**

   ```matlab
   % Weekly stats (returns table)
   stats = getWeeklyStats(5, 2023);

   % Play-by-play data filtered by team
   [pbp, meta] = getPlayByPlay(2023, 5, "KC");

   % Visualise top performers
   plotTopPlayers("passing_yards", 5, 2023);

   % Build an interactive team dashboard
   showTeamDashboard("KC", 2023);
   ```

3. **Switch to system-call mode (optional)**

   ```matlab
   stats = getWeeklyStats(5, 2023, UseSystemCall=true);
   ```

## Suggested demos

- Weekly top-10 QBs by passing yards: `plotTopPlayers("passing_yards", week, season)`
- Team dashboard comparing projected vs actual wins: `showTeamDashboard(team, season)`
- Play-by-play analysis for marquee games: `getPlayByPlay(season, week, team)`
- Roster exploration (average age/height/weight) via dashboard third tile
- Seasonal win trend by aggregating weekly tables returned from `getWeeklyStats`

## Extending the toolbox

- Add new MATLAB wrappers by reusing `nfl.internal.callWrapper` and
  `nfl.internal.payloadToTable` to convert JSON payloads into tables.
- Enhance the Python wrapper with additional arguments (e.g., column subsets,
  caching controls) while keeping JSON responses stable.
- Wrap the Python functions into a FastMCP server for remote or multi-language
  access, then update MATLAB helpers to target that endpoint when desired.

## Testing tips

- Use MATLAB Live Scripts to combine narratives with executable analytics.
- Cache nfl_data_py downloads by setting its environment variables
  (see project documentation) to avoid repeated network calls during sessions.
- When running from system mode, ensure the selected `python` command can
  import both `nfl_data_py` and this project's wrapper module.

## Development workflow

- Run automated checks: `matlab -batch "scripts.runTests"`
- Package the toolbox: `matlab -batch "pkgFile = scripts.packageToolbox"`
