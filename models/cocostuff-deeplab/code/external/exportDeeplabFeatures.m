% Take the features/scores output by deeplab and convert them into a format
% that we can use in our analysis scripts.
%
% Copyright by Holger Caesar, 2016

% Settings
dataset = CocoStuffDataset();
global glFeaturesFolder;
netName = 'deeplabv2_vgg16';
iterName = 'iter50k';
srcFolder = fullfile('/home/holger/deeplab/deeplab-public-ver2', lower(dataset.name), 'features', netName, 'val', iterName, 'fc8');
targetFolder = fullfile(glFeaturesFolder, 'CNN-Models', 'Deeplab', dataset.name, [netName, '-run1-exp8c'], sprintf('features-prediction-test-%s', iterName));

if ~exist(targetFolder, 'dir')
    mkdir(targetFolder);
end

% Get images
[imageList, imageCount] = dataset.getImageListTst();

for imageIdx = 1 : imageCount
    printProgress('Exporting scores for image', imageIdx, imageCount, 5)
    
    % Get scores
    imageName = imageList{imageIdx};
    srcPath = fullfile(srcFolder, sprintf('%s_blob_0.mat', imageName));
    srcStruct = load(srcPath, 'data');
    scores = srcStruct.data;
    
    % Crop scores
    scores = permute(scores, [2 1 3]);
    imSize = dataset.getImageSize(imageName);
    cropSize = [size(scores, 1), size(scores, 2)];
    assert(all(cropSize >= imSize));
    scores = scores(1:imSize(1), 1:imSize(2), :);
    
    % Output scores
    targetPath = fullfile(targetFolder, [imageName, '.mat']);
    if exist(targetPath, 'file')
        fprintf('Warning: Output file exists, skipping %s...\n', targetPath);
        continue;
    end
    features = scores;
    save(targetPath, 'features', '-v7.3');
end