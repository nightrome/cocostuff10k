function exportImages()
% exportImages()
%
% Writes a viewable preview image for each annotation to
% data/output/preview/<user>.
%
% Copyright by Holger Caesar, 2016

% Settings
exportAllUsers = false;
dataFolder = fullfile(cocoStuff_root(), 'annotator', 'data');
imageFolder = fullfile(cocoStuff_root(), 'dataset', 'images');
annotationTopFolder = fullfile(dataFolder, 'output', 'annotations');
previewTopFolder = fullfile(dataFolder, 'output', 'preview');

% Read username
if exportAllUsers
    folderList = dir(annotationTopFolder);
    folderList = folderList([folderList.isdir] == 1);
    folderList = {folderList.name};
    folderList(1:2) = [];
    userNames = folderList(:);
else
    userNames = readLinesToCell(fullfile(dataFolder, 'input', 'user.txt'));
end

userCount = numel(userNames);
for userIdx = 1 : userCount
    userName = userNames{userIdx};
    fprintf('Processing images for user %s...\n', userName);
    
    % Read output images
    annotationFolder = fullfile(annotationTopFolder, userName);
    fileList = dir(annotationFolder);
    fileList = {fileList.name};
    fileList(1:2) = [];
    
    % Create previews
    previewFolder = fullfile(previewTopFolder, userName);
    if ~exist(previewFolder, 'dir')
        mkdir(previewFolder);
    end
    
    % Create colorMap
    rng(42);
    unprocessedColor = [1, 1, 1];
    unlabeledColor = [0, 0, 0];
    thingColor = jet(1);
    stuffColors = cmapStuff();
    stuffColors = stuffColors(2:end, :);
    colorMap = [unprocessedColor; unlabeledColor; thingColor; stuffColors];
    
    imageCount = numel(fileList);
    for imageIdx = 1 : imageCount
        fprintf('Writing image %d of %d for user %s...\n', imageIdx, imageCount, userName);
        
        % Check if file exists
        fileName = fileList{imageIdx};
        imageName = strrep(fileName, '.mat', '');
        imageName = strrep(imageName, 'mask-', '');
        outPath = fullfile(previewFolder, [imageName, '.png']);
        
        % Get image and labelMap
        imagePath = fullfile(imageFolder, [imageName, '.jpg']);
        inPath = fullfile(annotationFolder, fileName);
        inStruct = load(inPath, 'labelMap', 'labelNames');
        if ~exist('labelNames', 'var')
            labelNames = inStruct.labelNames;
            assert(size(colorMap, 1) == numel(labelNames));
        end
        labelMap = inStruct.labelMap;
        labelMapIm = ind2rgb(labelMap, colorMap);
        labelMapIm = imageInsertBlobLabels(labelMapIm, labelMap, labelNames);
        image = im2double(imread(imagePath));
        if size(image, 3) == 1
            image = cat(3, image, image, image);
        end
        if size(image, 1) ~= size(labelMapIm, 1) || size(image, 2) ~= size(labelMapIm, 2)
            fprintf('Warning: Wrong image size! Skipping %s\n', imageName);
            continue;
        end
        outImage = [image, labelMapIm];
        
        % Write to image
        imwrite(outImage, outPath);
    end
end