function pkgFile = packageToolbox(outputDir)
% packageToolbox Build the MATLAB NFL Analytics Toolbox distribution.
%   pkgFile = packageToolbox(outputDir) packages the toolbox described by
%   toolboxProject.prj and writes the resulting MLTBX file to outputDir
%   (defaults to the repository root). The function returns the full path to
%   the generated MLTBX file.
arguments
    outputDir (1,1) string = ""
end

thisFile = mfilename("fullpath");
repoRoot = fileparts(thisFile);
repoRoot = fileparts(repoRoot); % climb out of +scripts/

if strlength(outputDir) == 0
    outputDir = string(repoRoot);
elseif ~isfolder(outputDir)
    error("nfl:PackageOutputMissing", "Output directory does not exist: %s", outputDir);
end

projFile = fullfile(repoRoot, "toolboxProject.prj");
if ~isfile(projFile)
    error("nfl:ProjectFileMissing", "Expected project file at %s", projFile);
end

pkgFile = matlab.addons.toolbox.packageToolbox(projFile, "OutputDir", char(outputDir));

end
