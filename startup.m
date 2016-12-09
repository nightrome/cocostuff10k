function startup()
% startup()
%
% Startup scripts that adds all the required code folders to the Matlab path.
%
% Copyright by Holger Caesar, 2016

% Check that we are in the right folder
if ~strcmp(pwd(), fileparts(mfilename('fullpath')))
    fprintf('Warning: All scripts should be called from the root level of the COCO-Stuff repository!');
end

% Add folders to path
addpath('dataset/code');
addpath('models/cocostuff-deeplab/code');
addpath('annotator/code');