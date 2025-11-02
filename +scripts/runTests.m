function results = runTests()
% runTests Execute MATLAB unit tests for the NFL analytics toolbox.
%   results = runTests() executes all tests located in the tests folder and
%   returns the matlab.unittest.TestResult array.

thisFile = mfilename("fullpath");
repoRoot = fileparts(thisFile);
repoRoot = fileparts(repoRoot); % ascend from +scripts/

toolboxDir = fullfile(repoRoot, "toolbox");
if ~isfolder(toolboxDir)
    error("nfl:MissingToolboxDir", "Expected toolbox directory at %s", toolboxDir);
end

addpath(genpath(toolboxDir));

suite = matlab.unittest.TestSuite.fromFolder(fullfile(repoRoot, "tests"), ...
    "IncludingSubfolders", true);

runner = matlab.unittest.TestRunner.withTextOutput("Verbosity", 2);
results = runner.run(suite);

if nargout == 0
    assignin("base", "ans", results); %#ok<NASGU>
end

end
