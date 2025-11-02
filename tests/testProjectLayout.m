classdef testProjectLayout < matlab.unittest.TestCase
    % testProjectLayout Validate repository layout and helper paths.

    properties (Constant, Access = private)
        RepoRoot = fileparts(fileparts(mfilename("fullpath")));
        ToolboxRoot = fullfile(testProjectLayout.RepoRoot, "toolbox");
    end

    methods (TestClassSetup)
        function addToolboxToPath(testCase)
            import matlab.unittest.fixtures.PathFixture
            toolboxPath = genpath(testProjectLayout.ToolboxRoot);
            toolboxFolders = string(strsplit(toolboxPath, pathsep));
            toolboxFolders(toolboxFolders == "") = [];
            testCase.applyFixture(PathFixture(toolboxFolders));
        end
    end

    methods (Test)
        function projectRootMatchesRepository(testCase)
            import matlab.unittest.constraints.EndsWithSubstring
            resolvedRoot = string(nfl.internal.projectRoot());
            expectedRoot = string(testProjectLayout.RepoRoot);
            testCase.verifyThat(resolvedRoot, EndsWithSubstring(expectedRoot), ...
                "Project root helper should resolve to repository root.");
        end

        function pythonWrapperExistsOnDisk(testCase)
            import matlab.unittest.constraints.IsFile
            wrapperPath = fullfile(testProjectLayout.ToolboxRoot, "python", "nfl_data_py_wrapper.py");
            testCase.verifyThat(wrapperPath, IsFile, ...
                "Python wrapper must exist under toolbox/python.");
        end

        function toolboxContentsFilePresent(testCase)
            import matlab.unittest.constraints.IsFile
            contentsFile = fullfile(testProjectLayout.ToolboxRoot, "toolboxContents.m");
            testCase.verifyThat(contentsFile, IsFile, ...
                "toolboxContents.m should be present for Add-On Explorer integration.");
        end

        function localPythonDetectionPointsToVenv(testCase)
            import matlab.unittest.constraints.IsEqualTo
            pythonPath = string(nfl.internal.localPythonPath());
            testCase.verifyNotEmpty(pythonPath, ...
                "localPythonPath should return a non-empty string when .venv is present.");

            expected = string({ ...
                fullfile(testProjectLayout.RepoRoot, ".venv", "bin", "python"), ...
                fullfile(testProjectLayout.RepoRoot, ".venv", "bin", "python3"), ...
                fullfile(testProjectLayout.RepoRoot, ".venv", "Scripts", "python.exe") ...
                });
            % Combine equality constraints so any expected executable passes.
            acceptableTargets = arrayfun(@(p) IsEqualTo(p), expected, "UniformOutput", false);
            combinedConstraint = acceptableTargets{1};
            for idx = 2:numel(acceptableTargets)
                combinedConstraint = combinedConstraint | acceptableTargets{idx};
            end
            testCase.verifyThat(pythonPath, combinedConstraint, ...
                "localPythonPath should point to the project's virtual environment.");
        end
    end
end
