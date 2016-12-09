clear all; close all;

orig_folder = '/home/holger/deeplab/deeplab-public-ver2/cocostuff/features/deeplabv2_vgg16/val/fc8';
save_folder = '/home/holger/deeplab/deeplab-public-ver2/cocostuff/features/deeplabv2_vgg16/val/fc8-visualization';
dataset = CocoStuffDataset();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% You do not need to change values below
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imgs_dir = dir(fullfile(orig_folder, '*.mat'));

if ~exist(save_folder, 'dir')
    mkdir(save_folder)
end

tmp = load('pascal_seg_colormap.mat');
colormap = tmp.colormap;

for i = 1 : numel(imgs_dir)
    fprintf(1, 'processing %d (%d) ...\n', i, numel(imgs_dir));
    
    scoresStruct = load(fullfile(orig_folder, imgs_dir(i).name));
    scores = scoresStruct.data;
    
    scores = permute(scores, [2 1 3]);
    imSize = size(labelMap);
    cropSize = [size(scores, 1), size(scores, 2)];
    assert(all(cropSize >= imSize));
    scores = scores(1:imSize(1), 1:imSize(2), :);
    [~, outputMap] = max(scores, [], 3);
    outputMap = uint8(outputMap) - 1;
    
    imwrite(outputMap, colormap, fullfile(save_folder, strrep(imgs_dir(i).name, '.mat', '.png')));
end
