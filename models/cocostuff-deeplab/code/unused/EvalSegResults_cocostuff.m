
% Settings
global glFeaturesFolder;
dataset = CocoStuffDataset();
iterationName = 'iter20k';
featFolder = fullfile('/home/holger/deeplab/deeplab-public-ver2', 'cocostuff', 'features', 'deeplabv2_vgg16', 'val', iterationName, 'fc8');
statsPath = fullfile(glFeaturesFolder, 'CNN-Models', 'Deeplab', dataset.name, 'deeplabv2_vgg16-run1-exp8c', sprintf('stats-test-%s.mat', iterationName));

% Get images
[imageList, imageCount] = dataset.getImageListTst();
labelCount = dataset.labelCount;

if exist(statsPath, 'file')
    load(statsPath);
else
    confusion = zeros(labelCount, labelCount);
    for imageIdx = 1 : imageCount
        printProgress('Evaluating image', imageIdx, imageCount, 5);
        
        % Get GT
        imageName = imageList{imageIdx};
        labelMap = dataset.getImLabelMap(imageName);
        image = dataset.getImage(imageName);
        
        % Get scores
        featName = sprintf('%s_blob_0', imageName);
        featPath = fullfile(featFolder, [featName, '.mat']);
        featStruct = load(featPath);
        scores = featStruct.data;
        scores = permute(scores, [2 1 3]);
        imSize = size(labelMap);
        cropSize = [size(scores, 1), size(scores, 2)];
        assert(all(cropSize >= imSize));
        scores = scores(1:imSize(1), 1:imSize(2), :);
        [~, outputMap] = max(scores, [], 3);
        
        % Aggregate confusion
        ok = labelMap > 0;
        confusion = confusion + accumarray([labelMap(ok), outputMap(ok)], 1, size(confusion));
        
        if false
            cmap = jet(labelCount);
            subplot(2, 2, 1);
            imagesc(labelMap);
            colormap(cmap);
            subplot(2, 2, 2);
            imagesc(outputMap);
            colormap(cmap);
            subplot(2, 2, 3);
            imagesc(labelMap ~= outputMap);
            subplot(2, 2, 4);
            imagesc(image);
        end
    end
    
    % Compute performance
    [stats.pacc, stats.macc, stats.miu, stats.ius, stats.maccs] = confMatToAccuracies(confusion);
    stats.confusion = confusion;
    save(statsPath, '-struct', 'stats');
end
fprintf('Results:\n');
fprintf('pixelAcc: %5.2f, meanAcc: %5.2f, meanIU: %5.2f \n', 100 * stats.pacc, 100 * stats.macc, 100 * stats.miu);
