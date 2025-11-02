function rootPath = projectRoot()
% projectRoot Returns the root directory of the NFL MATLAB toolbox project.
%   The function resolves paths relative to this file's location so that
%   helper routines can find shared assets such as the Python wrapper.

currentFile = mfilename('fullpath');
internalDir = fileparts(currentFile);      % .../toolbox/+nfl/+internal
pkgDir = fileparts(internalDir);           % .../toolbox/+nfl
toolboxDir = fileparts(pkgDir);            % .../toolbox
rootPath = fileparts(toolboxDir);          % project root
end
