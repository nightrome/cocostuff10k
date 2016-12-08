folder = '/home/holger/Documents/CodeForeign/cocostuff-annotator/data/output/annotations/s1452787';
fileList = dir(folder);
fileList = {fileList.name};
fileList(1:2) = [];
fileCount = numel(fileList);


for fileIdx = 1 : fileCount
    imageName = fileList{fileIdx};
    fileStruct = load(fullfile(folder, imageName), 'labelMap', 'imageSize');
    if fileStruct.imageSize(1) ~= size(fileStruct.labelMap, 1) || fileStruct.imageSize(2) ~= size(fileStruct.labelMap, 2)
        fprintf('%s\n', imageName);
    end
end