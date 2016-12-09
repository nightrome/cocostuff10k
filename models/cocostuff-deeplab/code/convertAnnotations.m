function convertAnnotations()
% convertAnnotations()
%
% Convert the COCO-Stuff annotation files into a suitable format for
% DeepLab. Offsets the label indices by -1 and converts them to uint8.
%
% Copyrights by Holger Caesar, 2016

% Add general code folder to path
cocoStuffFolder = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(fullfile(cocoStuffFolder, 'dataset', 'code'));

% Settings
annotationFolder = fullfile(cocoStuffFolder, 'dataset', 'annotations');
saveFolder = fullfile(cocoStuffFolder, 'models', 'cocostuff-deeplab', 'deeplab-public-ver2', 'cocostuff', 'data', 'annotations');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% You do not need to change values below
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imgs_dir = dir(fullfile(annotationFolder, '*.mat'));

if ~exist(saveFolder, 'dir')
    mkdir(saveFolder)
end

for i = 1 : numel(imgs_dir)
    fprintf(1, 'processing %d (%d) ...\n', i, numel(imgs_dir));
    
    labelStruct = load(fullfile(annotationFolder, imgs_dir(i).name));
    labelMap = labelStruct.S;
    assert(max(labelMap(:)) <= 172);
    labelMap = labelMap - 1;
    labelMap(labelMap == -1) = 255;
    labelMap = uint8(labelMap);
    
    imwrite(labelMap, fullfile(saveFolder, strrep(imgs_dir(i).name, '.mat', '.png')));
end
