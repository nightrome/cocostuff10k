function extractPseudoSuperpixels()
% extractPseudoSuperpixels()
%
% Extracts pseudo superpixels for each image in the imageList of the current user.
% Pseudo superpixels are actually single pixels, but stored in the same
% format as superpixels.
% This script does not include the known thing classes from COCO and
% therefore the field labelMapThings is set to dummy values.
%
% Copyright by Holger Caesar, 2017

% Settings
rootFolder = cocoStuff_root();
dataFolder = fullfile(rootFolder, 'annotator', 'data');
userPath = fullfile(dataFolder, 'input', 'user.txt');
imageFolder = fullfile(dataFolder, 'input', 'images');
imageListFolder = fullfile(dataFolder, 'input', 'imageLists');
outputFolder = fullfile(dataFolder, 'input', 'regions', 'pixels');

% Create output folder
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder)
end

% Read username
userNames = readLinesToCell(userPath);
userName = userNames{1};

% Read input images
imageListPath = fullfile(imageListFolder, sprintf('%s.list', userName));
imageList = readLinesToCell(imageListPath);
imageCount = numel(imageList);

for imageIdx = 1 : imageCount
    % Get image and regions
    imageName = imageList{imageIdx};
    imagePath = fullfile(imageFolder, [imageName, '.jpg']);
    image = imread(imagePath);
    imageSize = [size(image, 1), size(image, 2)];
    regionMap = getRegionsPseudo(image);
    labelMapThings = ones(imageSize);
    regionBoundaries = false(size(regionMap));
    
    % Some checks
    assert(all(imageSize == size(labelMapThings)));
    assert(all(imageSize == size(regionBoundaries)));
    assert(all(imageSize == size(regionMap)));
    assert(isa(labelMapThings, 'double'));
    assert(isa(regionBoundaries, 'logical'));
    assert(isa(regionMap, 'double'));
    
    % Save to file
    regionStruct.labelMapThings = labelMapThings;
    regionStruct.regionBoundaries = regionBoundaries;
    regionStruct.regionMap = regionMap;
    outputPath = fullfile(outputFolder, [imageName, '.mat']);
    save(outputPath, '-struct', 'regionStruct');
end

function[map] = getRegionsPseudo(image)
% [map] = getRegionsPseudo(image)
%
% Returns each pixel as a superpixel.

pixelCount = size(image, 1) * size(image, 2);
map = reshape(1:pixelCount, size(image, 1), size(image, 2));