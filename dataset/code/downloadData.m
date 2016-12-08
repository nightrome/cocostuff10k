function downloadData()
% downloadData()
%
% Downloads the data files of the COCO-Stuff dataset.
% This data includes annotations, images and imageLists.
%
% Copyright by Holger Caesar, 2016

% Settings
datasetFile = 'cocostuff-data-v1.0.zip';
datasetBaseUrl = 'http://calvin.inf.ed.ac.uk/wp-content/uploads/data/cocostuffdataset';
datasetUrl = fullfile(datasetBaseUrl, datasetFile);
datasetFolder = cocoStuff_root();
downloadFolder = fullfile(datasetFolder, '..', 'downloads');
datasetImageFolder = fullfile(datasetFolder, 'images');
datasetFile = fullfile(downloadFolder, datasetFile);

% Create download folder if it does not exist
if ~exist(downloadFolder, 'dir')
    mkdir(downloadFolder);
end

% Download the .zip file if it does not exist
if ~exist(datasetFile, 'file')
    fprintf('Downloading COCO-Stuff files to: %s...\n', datasetFile);
    websave(datasetFile, datasetUrl);
end

% Unpack the zip file if it hasn't been unpacked already
if ~exist(datasetImageFolder, 'dir')
    fprintf('Unpacking COCO-Stuff files to: %s...\n', datasetFolder);
    unzip(datasetFile, datasetFolder);
end