% exportImages()
%
% Writes a viewable image to data/output/preview/<UUN>
%
% Copyright by Holger Caesar, 2016

% Settings
datasetStuff = CocoStuffDatasetSimplified();
exportAllUsers = false;
dataFolder = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
imageFolder = fullfile(dataFolder, 'input', 'images');
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
    stuffLabels = sort(datasetStuff.getLabelNames());
    labelNames = ['unlabeled'; 'none'; 'things'; 'things'; stuffLabels];
    stuffCount = numel(stuffLabels);
    unlabeledColor = [1, 1, 1];
    noneColor = [0, 0, 0];
    otherColors = jet(stuffCount+1);
    thingColor = otherColors(1, :);
    stuffColors = otherColors(2:end, :);
    stuffColors = stuffColors(randperm(stuffCount), :);
    colorMap = [unlabeledColor; noneColor; thingColor; thingColor; stuffColors];
    
    imageCount = numel(fileList);
    for imageIdx = 1 : imageCount
        %fprintf('Writing image %d of %d for user %s...\n', imageIdx, imageCount, userName);
        
        % Check if file exists
        fileName = fileList{imageIdx};
        imageName = strrep(fileName, '.mat', '');
        imageName = strrep(imageName, 'mask-', '');
        outPath = fullfile(previewFolder, [imageName, '.png']);
        if exist(outPath, 'file')
            continue;
        end
        
        % Get image and labelMap
        imagePath = fullfile(imageFolder, [imageName, '.jpg']);
        inPath = fullfile(annotationFolder, fileName);
        inStruct = load(inPath, 'labelMap');
        labelMap = inStruct.labelMap;
        imageLabelMap = ind2rgb(labelMap, colorMap);
        imageLabelMap = imageInsertBlobLabels(imageLabelMap, labelMap, labelNames);
        image = im2double(imread(imagePath));
        if size(image, 3) == 1
            image = cat(3, image, image, image);
        end
        if size(image, 1) ~= size(imageLabelMap, 1) || size(image, 2) ~= size(imageLabelMap, 2)
            fprintf('Warning: Wrong image size! Skipping %s\n', imageName);
            continue;
        end
        outImage = [image, imageLabelMap];
        
        % Write to image
        imwrite(outImage, outPath);
    end
end