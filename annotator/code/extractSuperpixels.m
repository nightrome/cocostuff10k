function extractSuperpixels()
% extractSuperpixels()
%
% Extracts SLICO superpixels for each image in the imageList of the current user.
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
regionTargetCount = 1000;
slicoUrl = 'http://ivrl.epfl.ch/files/content/sites/ivrg/files/supplementary_material/RK_SLICsuperpixels/SLIC_mex.zip';
slicoDownloadPath = fullfile(rootFolder, 'downloads', 'SLIC_mex.zip');
slicoTargetFolder = fullfile(rootFolder, 'downloads', 'SLIC_mex');
slicoTargetSubFolder = fullfile(slicoTargetFolder, 'SLIC_mex');
slicoMexPath = fullfile(slicoTargetSubFolder, 'slicomex.c');
slicoMexTarget = fullfile(rootFolder, 'slicomex.mexa64');
outputFolder = fullfile(dataFolder, 'input', 'regions', sprintf('slico-%d', regionTargetCount));

% Install SLICO
if ~exist(slicoDownloadPath, 'file')
    websave(slicoDownloadPath, slicoUrl);
end
if ~exist(slicoTargetFolder, 'dir')
    unzip(slicoDownloadPath, slicoTargetFolder);
end
if ~exist(slicoMexTarget, 'file')
    params = 'CFLAGS="\$CFLAGS -std=c99"';
    mex(params, slicoMexPath);
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
    regionMap = getRegionsSLICO(image, regionTargetCount);
    labelMapThings = ones(imageSize);
    regionBoundaries = getRegionBoundaries(regionMap);
    
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

function[map] = getRegionsSLICO(image, regionTargetCount)
% [map] = getRegionsSLICO(image, regionTargetCount)
%
% Get SLICO superpixels using the mex code from Achanta et al.

[map, dump] = slicomex(im2uint8(image), regionTargetCount); %#ok<ASGLU>
map = double(map);
map = map + 1;
assert(min(map(:)) == 1);

function[bounds] = getRegionBoundaries(regionMap)
% [bounds] = getRegionBoundaries(regionMap)
%
% Extracts and post-processes the superpixel boundaries.

% Extract boundaries
bounds = superPixelMapToBoundaries(regionMap);

% Make thinner lines and then fix outer boundaries again
bounds = bwmorph(bounds, 'thin', Inf);
bounds(1, :) = true;
bounds(end, :) = true;
bounds(:, 1) = true;
bounds(:, end) = true;

function[bounds] = superPixelMapToBoundaries(regionMap)
% [bounds] = superPixelMapToBoundaries(regionMap)
%
% Converts a map of regions indices to a binary map where true indicates region boundaries.

% Perform a convolution in each possible direction to find out
% whether a pixel lies on a boundary
bounds = false(size(regionMap));
for i = [1:4, 6:9] % for 4-connectivity use [2, 4, 6, 8]
    filter = zeros(3, 3);
    filter(5) = 1;
    filter(i) = -1;
    bounds = bounds | conv2(double(regionMap), filter, 'same') ~= 0;
end