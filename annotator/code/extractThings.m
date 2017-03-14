function extractThings()
% extractThings()
%
% Gets the thing pixels from the COCO dataset and places them in a 2D map.
% (loses depth ordering) This is done for each image in the imageList of the current user.
%
% Copyright by Holger Caesar, 2017

% Settings
rootFolder = cocoStuff_root();
dataFolder = fullfile(rootFolder, 'annotator', 'data');
downloadFolder = fullfile(rootFolder, 'downloads');
userPath = fullfile(dataFolder, 'input', 'user.txt');
imageFolder = fullfile(rootFolder, 'dataset', 'images');
imageListFolder = fullfile(dataFolder, 'input', 'imageLists');
thingFolder = fullfile(dataFolder, 'input', 'things');
cocoUrl = 'http://msvocds.blob.core.windows.net/annotations-1-0-3/instances_train-val2014.zip';
cocoDownloadPath = fullfile(downloadFolder, 'instances_train-val2014.zip');
cocoTargetFolder = fullfile(downloadFolder, 'instances_train-val2014');
cocoInstancesTarget = fullfile(cocoTargetFolder, 'annotations', 'instances_train2014.json');
apiUrl = 'https://github.com/pdollar/coco/archive/336d2a27c91e3c0663d2dcf0b13574674d30f88e.zip';
apiDownloadPath = fullfile(downloadFolder, 'cocoApi.zip');
apiTargetFolder = fullfile(downloadFolder, 'cocoApi');

% Download & install COCO
if ~exist(cocoDownloadPath, 'file')
    fprintf('Downloading COCO annotations (158MB)...\n');
    websave(cocoDownloadPath, cocoUrl);
end
if ~exist(cocoTargetFolder, 'dir')
    fprintf('Unzipping COCO annotations...\n');
    unzip(cocoDownloadPath, cocoTargetFolder);
end

% Download & install COCO API
if ~exist(apiDownloadPath, 'file')
    fprintf('Downloading COCO API (3MB)...\n');
    websave(apiDownloadPath, apiUrl);
end
if ~exist(apiTargetFolder, 'dir')
    fprintf('Unzipping COCO annotations...\n');
    unzip(apiDownloadPath, apiTargetFolder);
end

% Init Coco API
fprintf('Loading COCO API...\n');
addpath(genpath(apiTargetFolder));
cocoApi = CocoApi(cocoInstancesTarget);

% Create output folder
if ~exist(thingFolder, 'dir')
    mkdir(thingFolder)
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
    
    % Get label map and flatten it to a binary map
    labelMap = getImLabelMap(cocoApi, image, imageName);
    labelMapThings = labelMap ~= 1; %#ok<NASGU>
    
    % Save to file
    outputPath = fullfile(thingFolder, [imageName, '.mat']);
    save(outputPath, 'labelMapThings');
end

function[labelMap] = getImLabelMap(cocoApi, image, imageName)

% Settings
useCrowd = true;
cocoSet = 'train2014';

% Load things from COCO
imgId = regexprep(imageName, sprintf('COCO_%s_', cocoSet), '');
imgId = str2double(imgId);
annIds = cocoApi.getAnnIds('imgIds', imgId, 'iscrowd', []);
anns = cocoApi.loadAnns(annIds);

% Filter crowd annotations
if ~useCrowd
    anns = anns([anns.iscrowd] ~= 1);
end

% Process the annotations in reverse order to have the correct
% depth order
annsCount = numel(anns);
imageSize = size(image);
labelMap = zeros(imageSize(1), imageSize(2));
for regionIdx = annsCount : -1 : 1
    curSegs = anns(regionIdx).segmentation;
    
    if isstruct(curSegs)
        M = double(MaskApi.decode(curSegs));
        [ys, xs] = find(M);
        inds = sub2ind(size(labelMap), ys, xs);
        labelMap(inds) = cocoApi.inds.catIdsMap(anns(regionIdx).category_id);
    else
        for j = 1 : length(curSegs)
            P = curSegs{j} + .5;
            xs = P(1:2:end);
            ys = P(2:2:end);
            BW = poly2mask(xs, ys, imageSize(1), imageSize(2));
            [ys, xs] = find(BW);
            inds = sub2ind(size(labelMap), ys, xs);
            labelMap(inds) = cocoApi.inds.catIdsMap(anns(regionIdx).category_id);
        end
    end
end
labelMap = labelMap + 1;