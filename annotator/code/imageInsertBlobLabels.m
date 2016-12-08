function[labelImage] = imageInsertBlobLabels(labelImage, labelMap, labelNames, varargin)
% [labelImage] = imageInsertBlobLabels(labelImage, labelMap, labelNames, varargin)
%
% Uses textInserter (from Vision Toolbox) to insert a cell of strings into
% the image. Each label is positioned at the center of mass of its blob.
%
% Test case (should output a red 'c' on a white image):
% labelImage = ones(256, 256, 3);
% labelMap = zeros(256, 256);
% labelMap(100, 100) = 3;
% labelMap(101, 100) = 3;
% labelNames = {'a', 'b', 'c'};
% outImage = imageInsertBlobLabels(labelImage, labelMap, labelNames, 'fontColor', [255, 0, 0], 'minComponentSize', 1);
% imshow(outImage);
%
% Copyright by Holger Caesar, 2014

% Parse input
p = inputParser;
addParameter(p, 'fontSize', 15);
addParameter(p, 'fontWidth', 8);
addParameter(p, 'fontColor', [26, 232, 222]);
addParameter(p, 'minComponentSize', 100); % at least 2px
addParameter(p, 'skipLabelInds', []); % labels that are ignored
parse(p, varargin{:});

fontSize = p.Results.fontSize;
fontWidth = p.Results.fontWidth;
fontColor = p.Results.fontColor;
minComponentSize = p.Results.minComponentSize;
skipLabelInds = p.Results.skipLabelInds;

% Check inputs
assert(~isa(labelMap, 'gpuArray'));

% Get unique list of labels
labelList = double(unique(labelMap(:)));
labelList(labelList == 0) = [];
labelListCount = numel(labelList);
if labelListCount == 0
    % Don't do anything if there are no labels
    return;
end

% Init
pixelIdxLists = cell(labelListCount, 1);
pixelIdxLabels = cell(labelListCount, 1);
usedMap = false(size(labelMap));

% Get the indices for all blobs
for labelMapUnIdx = 1 : labelListCount
    labelIdx = labelList(labelMapUnIdx);
    
    % Get connected components of that label
    components = bwconncomp(labelMap == labelIdx);
    pixelIdxList = components.PixelIdxList(:);
    sel = cellfun(@(x) numel(x), pixelIdxList) >= minComponentSize;
    pixelIdxList = pixelIdxList(sel);
    pixelIdxLabels{labelMapUnIdx} = ones(numel(pixelIdxList), 1) .* labelIdx;
    pixelIdxLists{labelMapUnIdx} = pixelIdxList;
end

% Convert cell to matrix
pixelIdxLists = flattenCellArray(pixelIdxLists);
pixelIdxLabels = cell2mat(pixelIdxLabels);
assert(numel(pixelIdxLists) == numel(pixelIdxLabels));
compCount = numel(pixelIdxLists);

% Sort by size
[~, sortOrder] = sort(cellfun(@numel, pixelIdxLists), 'descend');
pixelIdxLists = pixelIdxLists(sortOrder);
pixelIdxLabels = pixelIdxLabels(sortOrder);

for compIdx = 1 : compCount
    labelIdx = pixelIdxLabels(compIdx);
    if ismember(labelIdx, skipLabelInds)
        continue;
    end
    labelName = labelNames{labelIdx};
    
    % Get list of relevant pixels
    pixInds = pixelIdxLists{compIdx};
    pixInds = setdiff(pixInds, find(usedMap(:)));
    if isempty(pixInds)
        continue;
    end
    
    % Compute center of mass
    [y, x] = ind2sub(size(labelMap), pixInds);
    yCenter = median(y);
    xCenter = median(x);
    
    height = fontSize;
    width = fontWidth * numel(labelName);
    yStart = max(1, round(yCenter - height / 2));
    xStart = max(1, round(xCenter - width / 2));
    yEnd = min(yStart + height - 1, size(usedMap, 1));
    xEnd = min(xStart + width  - 1, size(usedMap, 2));
    
    if any(any(usedMap(yStart:yEnd, xStart:xEnd)))
        continue;
    end
    
    % Place label here
    textInserter = vision.TextInserter(labelName, 'Color', fontColor, ...
        'Location', [xStart, yStart], 'FontSize', fontSize, 'Font',  'LucidaSansDemiBold');
    labelImage = step(textInserter, labelImage);
    
    % Mark those pixels as used
    usedMap(yStart:yEnd, xStart:xEnd) = true;
end;