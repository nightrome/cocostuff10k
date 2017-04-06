function upgradeLabelsToVersion11()
% upgradeLabelsToVersion11()
%
% This script takes the unzipped contents of cocostuff-10k-v1.0.zip and
% converts the annotations from version 1.0 to 1.1, where COCO has 91 thing
% classes instead of 80. Afterwards the annotations1.1 folder needs to be
% manually renamed to annotations.
%
% Copyright by Holger Caesar, 2017

% Settings
cocoStuffFolder = '/home/holger/Downloads/cocostuff-10k-v1.0';
inputFolder = fullfile(cocoStuffFolder, 'annotations');
outputFolder = fullfile(cocoStuffFolder, 'annotations1.1');

% Create output Folder
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Get file list
[fileList, fileCount] = dirSubfolders(inputFolder, '.mat', true);

for fileIdx = 1 : fileCount
    % Check if output file exists
    fileName = fileList{fileIdx};
    filePath = fullfile(inputFolder, [fileName, '.mat']);
    outFilePath = fullfile(outputFolder, [fileName, '.mat']);
    if exist(outFilePath, 'file')
        fprintf('Skipping existing file: %s\n', outFilePath);
        continue;
    end
    
    % Load file
    fileStruct = load(filePath);
    
    % Update names
    assert(numel(fileStruct.names) == 172)
    thingNames = {'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck', 'boat', 'traffic light', 'fire hydrant', 'street sign', 'stop sign', 'parking meter', 'bench', 'bird', 'cat', 'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe', 'hat', 'backpack', 'umbrella', 'shoe', 'eyeglasses', 'handbag', 'tie', 'suitcase', 'frisbee', 'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove', 'skateboard', 'surfboard', 'tennis racket', 'bottle', 'plate', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch', 'potted plant', 'bed', 'mirror-things', 'dining table', 'window', 'desk-things', 'toilet', 'door-things', 'tv', 'laptop', 'mouse', 'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink', 'refrigerator', 'blender', 'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier', 'toothbrush', 'hairbrush'}';
    stuffNames = fileStruct.names(82:end)';
    assert(isempty(intersect(thingNames, stuffNames)));
    namesNew = [thingNames; stuffNames]; % Unlabeled is not listed anymore and will take label 0
    
    % Create mapping from old to new
    mapping = [0; find(ismember(namesNew, fileStruct.names))];
    
    % Map labels
    Snew = mapping(fileStruct.S);
    regionLabelsStuffNew = mapping(fileStruct.regionLabelsStuff);
    assert(isequal(namesNew(Snew(Snew > 0)), fileStruct.names(fileStruct.S(Snew > 0))'));
    
    % Save changes
    fileStruct.names = namesNew;
    fileStruct.S = Snew;
    fileStruct.regionLabelsStuff = regionLabelsStuffNew;
    save(outFilePath, '-struct', 'fileStruct');
end