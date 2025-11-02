function tests = testProjectLayout
% testProjectLayout Validate repository structure expected by packaging scripts.

tests = functiontests(localfunctions);
end

function setupOnce(testCase)
repoRoot = fileparts(mfilename("fullpath"));
repoRoot = fileparts(repoRoot); % ascend from tests/
toolboxPath = genpath(fullfile(repoRoot, "toolbox"));
addpath(toolboxPath);

testCase.TestData.RepoRoot = repoRoot;
testCase.TestData.ToolboxPath = toolboxPath;
end

function teardownOnce(testCase)
if isfield(testCase.TestData, "ToolboxPath") && ~isempty(testCase.TestData.ToolboxPath)
    rmpath(testCase.TestData.ToolboxPath);
end
end

function testProjectRootMatches(testCase)
repoRoot = testCase.TestData.RepoRoot;
resolvedRoot = nfl.internal.projectRoot();
verifyTrue(testCase, endsWith(string(resolvedRoot), string(repoRoot)), ...
    "Project root helper should resolve to repository root.");
end

function testPythonWrapperExists(testCase)
repoRoot = testCase.TestData.RepoRoot;
wrapperPath = fullfile(repoRoot, "toolbox", "python", "nfl_data_py_wrapper.py");
verifyTrue(testCase, isfile(wrapperPath), ...
    "Python wrapper must exist under toolbox/python.");
end

function testToolboxContentsPresent(testCase)
repoRoot = testCase.TestData.RepoRoot;
contentsFile = fullfile(repoRoot, "toolbox", "toolboxContents.m");
verifyTrue(testCase, isfile(contentsFile), ...
    "toolboxContents.m should be present for Add-On Explorer integration.");
end

function testLocalPythonDetection(testCase)
pythonPath = nfl.internal.localPythonPath();
testCase.verifyTrue(~isempty(pythonPath) && strlength(pythonPath) > 0, ...
    "localPythonPath should return a non-empty string when .venv is present.");

expected = string({ ...
    fullfile(nfl.internal.projectRoot(), ".venv", "bin", "python"), ...
    fullfile(nfl.internal.projectRoot(), ".venv", "bin", "python3"), ...
    fullfile(nfl.internal.projectRoot(), ".venv", "Scripts", "python.exe") ...
    });
testCase.verifyTrue(any(pythonPath == expected), ...
    "localPythonPath should point to the project's virtual environment.");
end
