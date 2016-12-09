clear all; close all;

%dataset = 'VOC2012';
%orig_folder = fullfile('..', dataset, 'SegmentationClassAug_Visualization');
%save_folder = ['../', dataset, '/SegmentationClassAug'];

%orig_folder = '/rmt/work/deeplabel/exper/voc12/res/erode_gt/post_densecrf_W41_XStd33_RStd4_PosW3_PosXStd3/results/VOC2012/Segmentation/comp6_trainval_aug_cls';
%save_folder = '/rmt/data/pascal/VOCdevkit/VOC2012/SegmentationClassBboxErodeCRFAug';

orig_folder = '/home/holger/deeplab/deeplab-public-ver2/cocostuff/data/PixelLabels';
save_folder = '/home/holger/deeplab/deeplab-public-ver2/cocostuff/data/annotations';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% You do not need to change values below
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imgs_dir = dir(fullfile(orig_folder, '*.mat'));

if ~exist(save_folder, 'dir')
    mkdir(save_folder)
end

for i = 1 : numel(imgs_dir)
    fprintf(1, 'processing %d (%d) ...\n', i, numel(imgs_dir));
    
    labelStruct = load(fullfile(orig_folder, imgs_dir(i).name));
    labelMap = labelStruct.S;
    labelMap = labelMap - 1;
    assert(max(labelMap(:)) <= 171);
    labelMap(labelMap == -1) = 255;
    labelMap = uint8(labelMap);
    
    imwrite(labelMap, fullfile(save_folder, strrep(imgs_dir(i).name, '.mat', '.png')));
end
