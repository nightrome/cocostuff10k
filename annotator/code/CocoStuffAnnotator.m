classdef CocoStuffAnnotator < handle & dynamicprops
    % COCO-Stuff image annotation class.
    %
    % This is the simplified version of the annotation tool used to
    % annotate the COCO-Stuff dataset. It annotates superpixels with a
    % paintbrush tool and clamps the known thing pixels from COCO.
    %
    % Requirements: For the two example images, take a look at
    % data/input/.. to see the files with their regions and thing labels.
    % All point coordinates are [y, x]
    % Keyboard: 1-9 for labels, +- for scale, left/right click for add/remove
    %
    % Copyright by Holger Caesar, 2017
    
    properties
        % Settings
        regionName = 'slico-1000'
        toolVersion = '0.9'
        useThings = true;
        useSuperpixels = true;
        usePolygons = false;
        
        % Main figure
        figMain
        containerButtons
        containerOptions
        containerStatus
        ax
        ui
        handleImage
        handleLabelMap
        handleBoundary
        handlePolygon
        
        % Pick label specific
        figLabelHierarchy
        ysLabelHierarchyIn
        xsLabelHierarchyIn
        ysLabelHierarchyOut
        xsLabelHierarchyOut
        categoriesLabelHierarchyIn
        categoriesLabelHierarchyOut
        
        % Class ids
        cls_unprocessed
        cls_unlabeled
        cls_things
        
        % Content fields
        labelIdx
        drawStatus = 0; % 0: nothing, 1: left click, 2: right click, 3: middle click
        drawModeDefault = 'superpixelDraw';
        drawMode = 'superpixelDraw';
        drawOverwrite = false;
        drawSizes = [1, 2, 5, 10, 15, 20, 30, 50, 100]';
        drawSize = 10;
        drawColors
        drawColor
        drawNow = false;
        labelMapTransparency = 0.6;
        boundaryTransparency = 0.2;
        
        % Administrative
        imageList
        labelNames
        datasetStuff
        dataFolder
        imageFolder
        regionFolder
        thingFolder
        outputFolder
        userName
        
        % Image-specific
        imageIdx = 1
        imageSize
        image
        imageName
        regionMap
        regionBoundaries
        labelMapUndo
        drawSizeMap
        timeMap
        timeDiffMap
        timerTotal
        timerImage
        timerImageDraw
        timeImageDraw
        timeImagePrevious
        timeImageDrawPrevious
        lastDrawTime
        
        % Polygon-specific
        curPolygon
    end
    
    methods
        % Constructor
        function obj = CocoStuffAnnotator()
            
            % Set timer
            obj.timerTotal = tic;
            
            % Setup folders
            obj.dataFolder = fullfile(cocoStuff_root(), 'annotator', 'data');
            obj.imageFolder = fullfile(cocoStuff_root(), 'dataset', 'images');
            
            % Read user name
            userNamePath = fullfile(obj.dataFolder, 'input', 'user.txt');
            userName = readLinesToCell(userNamePath);
            assert(numel(userName) == 1 && ~isempty(userName));
            obj.userName = userName{1};
            
            % Setup user folders
            obj.regionFolder  = fullfile(obj.dataFolder, 'input',  'regions', obj.regionName);
            obj.thingFolder  = fullfile(obj.dataFolder, 'input',  'things');
            obj.outputFolder = fullfile(obj.dataFolder, 'output', 'annotations', obj.userName);
            
            % Get image list
            imageListPath = fullfile(obj.dataFolder, 'input', 'imageLists', sprintf('%s.list', obj.userName));
            if ~exist(imageListPath, 'file')
                error('Error: Please check your username! Cannot find the imageList file at: %s\n', imageListPath);
            end
            obj.imageList = readLinesToCell(imageListPath);
            obj.imageList(cellfun(@isempty, obj.imageList)) = [];
            
            % Fix randomness
            rng(42);
            
            % Get dataset options
            stuffLabels = CocoStuffClasses.getLabelNamesStuff();
            obj.labelNames = ['unprocessed'; 'unlabeled'; 'things'; stuffLabels];
            obj.cls_unprocessed = find(strcmp(obj.labelNames, 'unprocessed'));
            obj.cls_unlabeled = find(strcmp(obj.labelNames, 'unlabeled'));
            obj.cls_things = find(strcmp(obj.labelNames, 'things'));
            obj.labelIdx = obj.cls_unlabeled;
            labelCount = numel(obj.labelNames);
            unprocessedColor = [1, 1, 1];
            unlabeledColor = [0, 0, 0];
            otherColors = jet(numel(stuffLabels)+1);
            thingColor = otherColors(1, :);
            stuffColors = otherColors(2:end, :);
            stuffColors = stuffColors(randperm(size(stuffColors, 1)), :);
            obj.drawColors = [unprocessedColor; unlabeledColor; thingColor; stuffColors];
            obj.drawColor = obj.drawColors(obj.labelIdx, :);
            assert(size(obj.drawColors, 1) == labelCount);
            
            % Create figure
            obj.figMain = figure(...
                'MenuBar', 'none',...
                'NumberTitle', 'off');
            obj.updateTitle();
            set(obj.figMain, 'CloseRequestFcn', @(src,event) onclose(obj,src,event))
            
            % Set figure size
            figSize = [800, 800];
            figPos = get(obj.figMain, 'Position');
            figPos(3) = figSize(2);
            figPos(4) = figSize(1);
            set(obj.figMain, 'Position', figPos);
            
            % Create form containers
            menuLeft = 0.0;
            menuRight = 1.0;
            obj.containerButtons = uiflowcontainer('v0', obj.figMain, 'Units', 'Norm', 'Position', [menuLeft, .95, menuRight, .05]);
            obj.containerOptions = uiflowcontainer('v0', obj.figMain, 'Units', 'Norm', 'Position', [menuLeft, .90, menuRight, .05]);
            
            % Create buttons
            obj.ui.buttonLabelHierarchy = uicontrol(obj.containerButtons, ...
                'String', 'Label hierarchy', ...
                'Callback', @(handle, event) obj.buttonLabelHierarchyClick(), ...
                'Tag', 'buttonLabelHierarchy');
            
            obj.ui.buttonPickLabel = uicontrol(obj.containerButtons, ...
                'String', 'Pick label', ...
                'Callback', @(handle, event) obj.buttonPickLabelClick(), ...
                'Tag', 'buttonPickLabel');
            
            obj.ui.buttonClearLabel = uicontrol(obj.containerButtons, ...
                'String', 'Clear label', ...
                'Callback', @(handle, event) obj.buttonClearLabelClick(), ...
                'Tag', 'buttonClearLabel');
            
            obj.ui.buttonSwapLabel = uicontrol(obj.containerButtons, ...
                'String', 'Swap label', ...
                'Callback', @(handle, event) obj.buttonSwapLabelClick(), ...
                'Tag', 'buttonSwapLabel');
            
            obj.ui.buttonUndo = uicontrol(obj.containerButtons, ...
                'String', 'Undo', ...
                'Callback', @(handle, event) obj.buttonUndoClick(), ...
                'Tag', 'buttonUndo');
            
            obj.ui.buttonPrevImage = uicontrol(obj.containerButtons, ...
                'String', 'Prev image', ...
                'Callback', @(handle, event) obj.buttonPrevImageClick(), ...
                'Tag', 'buttonPrevImage');
            
            obj.ui.buttonJumpImage = uicontrol(obj.containerButtons, ...
                'String', 'Jump to image', ...
                'Callback', @(handle, event) obj.buttonJumpImageClick(), ...
                'Tag', 'buttonJumpImage');
            
            obj.ui.buttonNextImage = uicontrol(obj.containerButtons, ...
                'String', 'Next image', ...
                'Callback', @(handle, event) obj.buttonNextImageClick(), ...
                'Tag', 'buttonNextImage');
            
            % Create options
            labelNamesPopup = obj.labelNames;
            labelNamesPopup(strcmp(labelNamesPopup, 'unprocessed')) = [];
            labelNamesPopup(strcmp(labelNamesPopup, 'things')) = [];
            obj.ui.popupLabel = uicontrol(obj.containerOptions, ...
                'Style', 'popupmenu', ...
                'String', labelNamesPopup, ...
                'Callback', @(handle, event) popupLabelSelect(obj, handle, event));
            
            obj.ui.popupPointSize = uicontrol(obj.containerOptions, ...
                'Style', 'popupmenu', ...
                'String', cellfun(@num2str, mat2cell(obj.drawSizes, ones(size(obj.drawSizes))), 'UniformOutput', false), ...
                'Value', find(obj.drawSizes == obj.drawSize), ...
                'Callback', @(handle, event) popupPointSizeSelect(obj, handle, event));
            
            obj.ui.checkOverwrite = uicontrol(obj.containerOptions, ...
                'Style', 'checkbox',...
                'String', 'Overwrite',...
                'Value', obj.drawOverwrite, ...
                'Callback', @(handle, event) checkOverwriteChange(obj, handle, event));
            
            obj.ui.sliderMapTransparency = uicontrol(obj.containerOptions, ...
                'Style', 'slider', ...
                'Min', 0, 'Max', 100, 'Value', 100 * obj.labelMapTransparency, ...
                'Callback', @(handle, event) sliderMapTransparencyChange(obj, handle, event));
            
            obj.ui.sliderBoundaryTransparency = uicontrol(obj.containerOptions, ...
                'Style', 'slider', ...
                'Min', 0, 'Max', 100, 'Value', 100 * obj.boundaryTransparency, ...
                'Callback', @(handle, event) sliderBoundaryTransparencyChange(obj, handle, event));
            
            % Make sure labelIdx is the same everywhere
            obj.setLabelIdx(obj.labelIdx);
            
            % Specify axes
            obj.ax = axes('Parent', obj.figMain);
            obj.figResize();
            axis(obj.ax, 'off');
            
            % Show empty image
            axes(obj.ax);
            hold on;
            
            % Initialize handles with empty images
            obj.handleImage = imshow([]);
            obj.handleLabelMap = image([]);
            obj.handleBoundary = image([]);
            obj.handlePolygon = image([]);
            hold off;
            
            % Specify the colors for each label in the labelMap
            colormap(obj.ax, obj.drawColors);
            
            % Set axis units
            obj.ax.Units = 'pixels';
            
            % Image event callbacks
            set(obj.handleLabelMap, 'ButtonDownFcn', @(handle, event) handleClickDown(obj, handle, event));
            set(obj.handleBoundary, 'ButtonDownFcn', @(handle, event) handleClickDown(obj, handle, event));
            set(obj.handlePolygon,  'ButtonDownFcn', @(handle, event) handleClickDown(obj, handle, event));
            
            % Figure event callbacks
            set(obj.figMain, 'WindowButtonMotionFcn', @(handle, event) figMouseMove(obj, handle, event));
            set(obj.figMain, 'WindowButtonUpFcn', @(handle, event) figClickUp(obj, handle, event));
            set(obj.figMain, 'ResizeFcn', @(handle, event) figResize(obj, handle, event));
            set(obj.figMain, 'KeyPressFcn', @(handle, event) figKeyPress(obj, handle, event));
            set(obj.figMain, 'WindowScrollWheelFcn', @(handle, event) figScrollWheel(obj, handle, event));
            
            % Set fancy mouse pointer
            setCirclePointer(obj.figMain);
            
            % Set drawMode
            if obj.usePolygons
                obj.drawModeDefault = 'polygonDraw';
                obj.drawMode = 'polygonDraw';
            end
            
            % Load image
            obj.loadImage();
        end
        
        function loadImage(obj)
            % Reads the current imageIdx
            % Resets all image-specific settings and loads a new image
            
            % Set timer
            obj.timerImage = tic;
            obj.timeImageDraw = 0;
            obj.timerImageDraw = [];
            
            % Load image
            obj.imageName = obj.imageList{obj.imageIdx};
            obj.image     = imread(fullfile(obj.imageFolder, [obj.imageName, '.jpg']));
            obj.imageSize = size(obj.image);
            
            % Load regions from file
            if obj.useSuperpixels
                regionPath = fullfile(obj.regionFolder, sprintf('%s.mat', obj.imageName));
                if exist(regionPath, 'file')
                    regionStruct = load(regionPath, 'regionMap', 'regionBoundaries');
                    obj.regionMap = regionStruct.regionMap;
                    obj.regionBoundaries = regionStruct.regionBoundaries;
                else
                    error('Error: Cannot find region file: %s\n', regionPath);
                end
            else
                pixelCount = obj.imageSize(1) * obj.imageSize(2);
                obj.regionMap = reshape(1:pixelCount, obj.imageSize(1), obj.imageSize(2));
                obj.regionBoundaries = false(obj.imageSize(1:2));
            end
            
            % Load things from file if specified
            thingPath = fullfile(obj.thingFolder, sprintf('%s.mat', obj.imageName));
            if obj.useThings && exist(thingPath, 'file')
                % Load things
                thingStruct = load(thingPath, 'labelMapThings');
                labelMapThings = thingStruct.labelMapThings;
            elseif obj.useThings
                % Load dummy things and print warning
                labelMapThings = false(size(obj.regionMap));
                fprintf('Warning: Cannot find things file: %s\n', thingPath);
            else
                % Load dummy things and ignore
                labelMapThings = false(size(obj.regionMap));
            end
            
            % Load annotation if it already exists
            outputPath = fullfile(obj.outputFolder, sprintf('%s.mat', obj.imageName));
            if exist(outputPath, 'file')
                fprintf('Loading existing annotation %s...\n', outputPath);
                outputStruct = load(outputPath, 'labelMap', 'timeImage', 'timeImageDraw', 'timeMap', 'timeDiffMap', 'drawSizeMap', 'labelNames');
                labelMap = outputStruct.labelMap;
                obj.timeImagePrevious = outputStruct.timeImage;
                obj.timeImageDrawPrevious = outputStruct.timeImageDraw;
                
                % For compatibility
                if isfield(outputStruct, 'timeMap')
                    obj.timeMap = outputStruct.timeMap;
                end
                if isfield(outputStruct, 'timeDiffMap')
                    obj.timeDiffMap = outputStruct.timeDiffMap;
                end
                if isfield(outputStruct, 'drawSizeMap')
                    obj.drawSizeMap = outputStruct.drawSizeMap;
                end
                obj.lastDrawTime = [];
                
                % Make sure labels haven't changed since last time
                savedLabelNames = outputStruct.labelNames;
                assert(isequal(savedLabelNames, obj.labelNames));
                
                assert(obj.imageSize(1) == size(labelMap, 1) && obj.imageSize(2) == size(labelMap, 2) && size(labelMap, 3) == 1);
            else
                fprintf('Creating new annotation %s...\n', outputPath);
                labelMap = repmat(obj.cls_unprocessed, [obj.imageSize(1), obj.imageSize(2)]);
                labelMap(labelMapThings) = obj.cls_things;
                obj.timeImagePrevious = 0;
                obj.timeImageDrawPrevious = 0;
                obj.timeMap = nan(obj.imageSize(1:2));
                obj.timeDiffMap = nan(obj.imageSize(1:2));
                obj.drawSizeMap = nan(obj.imageSize(1:2));
                obj.lastDrawTime = [];
            end
            assert(min(labelMap(:)) >= 1);
            
            % Show images
            boundaryIm = zeros(obj.imageSize);
            boundaryIm(:, :, 1) = 1;
            polygonIm = repmat(obj.cls_unprocessed, obj.imageSize(1:2));
            
            obj.handleImage.CData = obj.image;
            obj.handleLabelMap.CData = labelMap;
            obj.handlePolygon.CData = polygonIm;
            obj.handleBoundary.CData = boundaryIm;
            
            % Set undo data
            obj.labelMapUndo = obj.handleLabelMap.CData;
            
            % Update alpha data
            obj.updateAlphaData();
            
            % Update figure title
            obj.updateTitle();
        end
        
        % Button callbacks
        function buttonLabelHierarchyClick(obj)
            if isempty(obj.figLabelHierarchy) || ~isvalid(obj.figLabelHierarchy)
                % Open new figure
                obj.figLabelHierarchy = figure('Name', 'Label hierarchy', ...
                    'MenuBar', 'none',...
                    'NumberTitle', 'off');
            else
                % Make figure active again
                figure(obj.figLabelHierarchy);
            end
            
            % Get label hierarchy
            [nodes, cats, heights] = CocoStuffClasses.getClassHierarchyStuff();
            
            % Plot label hierarchy
            obj.plotTree(nodes, cats, heights, 1);
            obj.plotTree(nodes, cats, heights, 2);
            
            % Set figure size
            pos = get(obj.figLabelHierarchy, 'Position');
            newPos = pos;
            newPos(3) = 1000;
            newPos(4) = 800;
            set(obj.figLabelHierarchy, 'Position', newPos);
        end
        
        function buttonPickLabelClick(obj)
            obj.drawMode = 'pickLabel';
        end
        
        function plotTree(obj, nodes, cats, heights, isIndoors) % isIndoors: indoors = 1, outdoors = 2
            % Get only relevant nodes and cats
            sel = false(size(nodes));
            if isIndoors == 1
                sel(2) = true;
            else
                sel(3) = true;
            end
            while true
                oldSel = sel;
                sel = sel | ismember(nodes, find(sel));
                if isequal(sel, oldSel)
                    break;
                end
            end
            nodes = nodes(sel);
            cats = cats(sel);
            heights = heights(sel);
            
            % Remap nodes in 0:x range
            map = false(max(nodes), 1);
            map(unique(nodes)) = true;
            map = cumsum(map)-1;
            nodes = map(nodes);
            
            % Plot them
            curAx = axes('Parent', obj.figLabelHierarchy, 'Units', 'Norm');
            axis(curAx, 'off');
            treeplot(nodes');
            if isIndoors == 1
                set(curAx, 'Position', [0, 0, 0.5, 1]);
            else
                set(curAx, 'Position', [0.5, 0, 0.5, 1]);
            end
            [xs, ys] = treelayout(nodes);
            
            % Set appearance settings and show labels
            isLeaf = ys == min(ys);
            textInner = text(xs(~isLeaf) + 0.01, ys(~isLeaf) - 0.025, cats(~isLeaf), 'VerticalAlignment', 'Bottom', 'HorizontalAlignment', 'right');
            textLeaf  = text(xs( isLeaf) - 0.01, ys( isLeaf) - 0.02,  cats( isLeaf), 'VerticalAlignment', 'Bottom', 'HorizontalAlignment', 'left');
            set(curAx, 'XTick', [], 'YTick', [], 'Units', 'Normalized');
            curAx.XLabel.String = '';
            
            % Rotate view
            camroll(90);
            
            % Store only selectable/leaf nodes
            selectable = heights == 3;
            cats = cats(selectable);
            ys = ys(selectable);
            xs = xs(selectable);
            
            if isIndoors == 1
                % Save to object
                obj.categoriesLabelHierarchyIn = cats;
                obj.ysLabelHierarchyIn = ys;
                obj.xsLabelHierarchyIn = xs;
                
                % Register callbacks
                set(curAx, 'ButtonDownFcn', @(handle, event) pickLabelInClick(obj, handle, event));
                set(textInner, 'ButtonDownFcn', @(handle, event) pickLabelInClick(obj, handle, event));
                set(textLeaf, 'ButtonDownFcn', @(handle, event) pickLabelInClick(obj, handle, event));
            else
                % Save to object
                obj.categoriesLabelHierarchyOut = cats;
                obj.ysLabelHierarchyOut = ys;
                obj.xsLabelHierarchyOut = xs;
                
                % Register callbacks
                set(curAx, 'ButtonDownFcn', @(handle, event) pickLabelOutClick(obj, handle, event));
                set(textInner, 'ButtonDownFcn', @(handle, event) pickLabelOutClick(obj, handle, event));
                set(textLeaf, 'ButtonDownFcn', @(handle, event) pickLabelOutClick(obj, handle, event));
            end
        end
        
        function pickLabelInClick(obj, ~, event)
            % Find closest label indoors
            pos = [event.IntersectionPoint(2), event.IntersectionPoint(1)];
            labelIdx = obj.findClosestLabelInTree(pos, obj.ysLabelHierarchyIn, obj.xsLabelHierarchyIn, obj.categoriesLabelHierarchyIn); %#ok<PROPLC>
            
            % Set globally
            obj.setLabelIdx(labelIdx); %#ok<PROPLC>
        end
        
        function pickLabelOutClick(obj, ~, event)
            % Find closest label outdoors
            pos = [event.IntersectionPoint(2), event.IntersectionPoint(1)];
            labelIdx = obj.findClosestLabelInTree(pos, obj.ysLabelHierarchyOut, obj.xsLabelHierarchyOut, obj.categoriesLabelHierarchyOut); %#ok<PROPLC>
            
            % Set globally
            obj.setLabelIdx(labelIdx); %#ok<PROPLC>
        end
        
        function[labelIdx] = findClosestLabelInTree(obj, pos, ys, xs, cats)
            dists = sqrt((ys - pos(1)) .^ 2 + (xs - pos(2)) .^ 2);
            [~, minDistInd] = min(dists);
            
            labelName = cats(minDistInd);
            labelIdx = find(strcmp(obj.labelNames, labelName));
        end
        
        function buttonSuperpixelDrawClick(obj)
            obj.drawMode = 'superpixelDraw';
            
            obj.ui.buttonPointDraw.Value = 0;
            obj.ui.buttonSuperpixelDraw.Value = 1;
        end
        
        function buttonClearLabelClick(obj)
            
            % Save data for undo feature
            obj.labelMapUndo = obj.handleLabelMap.CData;
            
            % Set all labels to 1 (unprocessed)
            obj.handleLabelMap.CData(obj.handleLabelMap.CData(:) == obj.labelIdx) = 1;
            
            obj.updateAlphaData();
        end
        
        function buttonSwapLabelClick(obj)
            % Ask for newLabel
            oldLabel = obj.labelNames{obj.labelIdx};
            message = sprintf('Please specify the new label for: %s', oldLabel);
            newLabel = inputdlg(message);
            assert(iscell(newLabel) && numel(newLabel) == 1);
            oldLabelIdx = obj.labelIdx;
            newLabelIdx = find(ismember(obj.labelNames, newLabel));
            
            % Check whether it is valid
            if ~ismember(newLabel, obj.labelNames)
                msgbox('Error: invalid label name!', 'Error','error');
                return;
            end
            
            % Check if label is present
            if ~ismember(oldLabelIdx, obj.handleLabelMap.CData)
                msgbox(sprintf('Error: No pixel has the label: %s', oldLabel), 'Error','error');
                return;
            end
            
            % Save labels for undo feature
            obj.labelMapUndo = obj.handleLabelMap.CData;
            
            % Swap labels
            obj.handleLabelMap.CData(obj.handleLabelMap.CData == oldLabelIdx) = newLabelIdx;
        end
        
        function saveOutput(obj)
            % Check if anything was annotated
            labelMap = obj.handleLabelMap.CData;
            outputPath = fullfile(obj.outputFolder, sprintf('%s.mat', obj.imageName));
            if all(labelMap(:) == obj.cls_unprocessed)
                fprintf('Not saving annotation for unedited image %s...\n', outputPath);
                return;
            end
            
            % Create folder
            if ~exist(obj.outputFolder, 'dir')
                mkdir(obj.outputFolder)
            end
            
            % Save output
            fprintf('Saving annotation output to %s...\n', outputPath);
            saveStruct.imageIdx = obj.imageIdx;
            saveStruct.imageSize = obj.imageSize;
            saveStruct.imageName = obj.imageName;
            saveStruct.labelMap = labelMap;
            saveStruct.labelNames = obj.labelNames;
            saveStruct.timeTotal = toc(obj.timerTotal);
            saveStruct.timeImage = obj.timeImagePrevious + toc(obj.timerImage);
            saveStruct.timeImageDraw = obj.timeImageDraw;
            saveStruct.timeMap = obj.timeMap;
            saveStruct.timeDiffMap = obj.timeDiffMap;
            saveStruct.drawSizeMap = obj.drawSizeMap;
            saveStruct.userName = obj.userName;
            save(outputPath, '-struct', 'saveStruct', '-v7.3');
        end
        
        function buttonUndoClick(obj)
            % Store undo info to redo
            tempMap = obj.handleLabelMap.CData;
            
            % Undo last drawing action (or clear label)
            obj.handleLabelMap.CData = obj.labelMapUndo;
            
            % Save temp maps
            obj.labelMapUndo = tempMap;
            
            obj.updateAlphaData();
        end
        
        function buttonPrevImageClick(obj)
            % Check if image is complete
            if obj.checkUnprocessed()
                choice = questdlg('There are unprocessed pixels. Would you like to continue?', 'Continue?');
                switch choice
                    case 'Yes'
                        % do nothing
                    otherwise
                        return;
                end
            end
            
            % Save current output
            obj.saveOutput();
            
            % Set new imageIdx
            obj.imageIdx = obj.imageIdx - 1;
            if obj.imageIdx < 1
                obj.imageIdx = numel(obj.imageList);
            end
            
            % Load new image
            obj.loadImage();
        end
        
        function buttonJumpImageClick(obj)
            % Check if image is complete
            if obj.checkUnprocessed()
                choice = questdlg('There are unprocessed pixels. Would you like to continue?', 'Continue?');
                switch choice
                    case 'Yes'
                        % do nothing
                    otherwise
                        return;
                end
            end
            
            % Ask for imageIdx
            message = sprintf('You are currently at image %d of %d. Please insert the number of the image you want to annotate (1 <= x <= %d):', obj.imageIdx, numel(obj.imageList), numel(obj.imageList));
            response = inputdlg(message);
            try
                response = str2double(response);
                if isempty(response)
                    % If the user cancelled the dialog, exit
                    return;
                end
                if isnan(response)
                    error('Error: Invalid number!');
                end
                if response < 1 || (numel(obj.imageList) < response)
                    error('Error: Number not in valid range: 1 <= x <= %d', numel(obj.imageList));
                end
                if mod(response, 1) ~= 0
                    error('Error: Only integers allowed!');
                end
            catch e
                msgbox(e.message, 'Error', 'error');
                return;
            end
            
            % Save current output
            obj.saveOutput();
            
            % Set new imageIdx
            obj.imageIdx = response;
            
            % Load new image
            obj.loadImage();
        end
        
        function buttonNextImageClick(obj)
            % Check if image is complete
            if obj.checkUnprocessed()
                choice = questdlg('There are unprocessed pixels. Would you like to continue?', 'Continue?');
                switch choice
                    case 'Yes'
                        % do nothing
                    otherwise
                        return;
                end
            end
            
            % Save current output
            obj.saveOutput();
            
            % Set new imageIdx
            obj.imageIdx = obj.imageIdx + 1;
            if obj.imageIdx > numel(obj.imageList)
                obj.imageIdx = 1;
            end
            
            % Load new image
            obj.loadImage();
        end
        
        function[res] = checkUnprocessed(obj)
            res = any(obj.handleLabelMap.CData(:) == 1);
        end
        
        function popupLabelSelect(obj, handle, event) %#ok<INUSD>
            % Set label
            labels = get(handle, 'string');
            selection = get(handle, 'value');
            label = labels{selection};
            labelIdx = find(strcmp(obj.labelNames, label)); %#ok<PROPLC>
            obj.setLabelIdx(labelIdx); %#ok<PROPLC,FNDSB>
        end
        
        function setLabelIdx(obj, labelIdx)
            % Set new value
            obj.labelIdx = labelIdx;
            if isempty(obj.labelIdx)
                error('Internal error: Unknown label picked!');
            end
            
            % Set popup value
            obj.ui.popupLabel.Value = find(strcmp(obj.ui.popupLabel.String, obj.labelNames{obj.labelIdx}));
            
            % Update color
            obj.drawColor = obj.drawColors(obj.labelIdx, :);
        end
        
        function popupPointSizeSelect(obj, handle, event) %#ok<INUSD>
            values = get(handle, 'string');
            selection = get(handle, 'value');
            obj.drawSize = str2double(values{selection});
        end
        
        function checkOverwriteChange(obj, handle, ~)
            obj.drawOverwrite = handle.Value;
        end
        
        function sliderMapTransparencyChange(obj, ~, event)
            obj.labelMapTransparency = event.Source.Value / 100;
            obj.updateAlphaData();
        end
        
        function sliderBoundaryTransparencyChange(obj, ~, event)
            obj.boundaryTransparency = event.Source.Value / 100;
            obj.updateAlphaData();
        end
        
        function handleClickDown(obj, handle, event) %#ok<INUSL>
            pos = round([event.IntersectionPoint(2), event.IntersectionPoint(1)]);
            if event.Button == 1
                % Left click
                obj.drawStatus = 1;
            elseif event.Button == 2
                % Middle click
                obj.drawStatus = 3;
            elseif event.Button == 3
                % Right click
                obj.drawStatus = 2;
            elseif event.Button == 2
                % Middle click (undo)
                obj.buttonUndoClick();
            end
            obj.drawPos(pos);
        end
        
        function figClickUp(obj, ~, ~)
            obj.drawStatus = 0;
        end
        
        function drawPos(obj, pos)
            % Only act when a mouse button was clicked
            if obj.drawStatus ~= 0
                % Initial values
                updatedPixels = false;
                labelIdx = obj.labelIdx; %#ok<PROPLC>
                
                if strcmp(obj.drawMode, 'pickLabel')
                    labelIdx = obj.handleLabelMap.CData(pos(1), pos(2)); %#ok<PROPLC>
                    
                    if labelIdx ~= 1 %#ok<PROPLC>
                        % Correct from read-only things to unlabeled
                        if labelIdx == obj.cls_things %#ok<PROPLC>
                            labelIdx = obj.cls_unlabeled; %#ok<PROPLC>
                        end
                        
                        % Update labelIdx globally
                        obj.setLabelIdx(labelIdx); %#ok<PROPLC>
                    end
                    
                    % Set to drawing mode
                    obj.drawMode = obj.drawModeDefault;
                elseif strcmp(obj.drawMode, 'polygonDraw')
                    if obj.drawStatus == 2
                        % Undo last click
                        
                        % Abort if not enough points
                        if size(obj.curPolygon, 1) <= 1
                            if size(obj.curPolygon, 1) == 1
                                obj.curPolygon = obj.curPolygon(1:end-1, :);
                            end
                            obj.handlePolygon.CData(:) = obj.cls_unprocessed;
                            obj.updateAlphaData();
                            return;
                        end
                        
                        % Remove last point
                        obj.curPolygon = obj.curPolygon(1:end-1, :);
                        
                        % Check that there was a last click
                        if size(obj.curPolygon, 1) < 1
                            return;
                        end
                        
                        % Reset polygon layer
                        obj.handlePolygon.CData(:) = obj.cls_unprocessed;
                        
                        % Update existing polygon preview
                        if size(obj.curPolygon, 1) >= 3
                            mask = poly2mask(obj.curPolygon(:, 2), obj.curPolygon(:, 1), obj.imageSize(1), obj.imageSize(2));
                            [ys, xs] = find(mask);
                            inds = sub2ind(obj.imageSize(1:2), ys, xs);
                            obj.handlePolygon.CData(inds) = labelIdx; %#ok<PROPLC>
                        end
                        
                        obj.updateAlphaData();
                        
                    elseif obj.drawStatus == 3
                        % Close polygon
                        % (if we are close to the start or pressed right
                        % click)
                        
                        % Only close it if we have at least 3 points
                        if size(obj.curPolygon, 1) < 3
                            return;
                        end
                        
                        % Reset polygon layer
                        obj.handlePolygon.CData(:) = obj.cls_unprocessed;
                        
                        % Get pixels inside polygon
                        mask = poly2mask(obj.curPolygon(:, 2), obj.curPolygon(:, 1), obj.imageSize(1), obj.imageSize(2));
                        [ys, xs] = find(mask);
                        inds = sub2ind(obj.imageSize(1:2), ys, xs);
                        
                        % Reset polygon
                        obj.curPolygon = [];
                        
                        % Reset polygon layer
                        obj.handlePolygon.CData(:) = obj.cls_unprocessed;
                        
                        % Set update flag
                        updatedPixels = true;
                    else
                        % Add new point
                        obj.curPolygon = [obj.curPolygon; pos]; % each row: y, x
                        
                        % Reset polygon layer
                        obj.handlePolygon.CData(:) = obj.cls_unprocessed;
                        
                        % Update existing polygon preview
                        if size(obj.curPolygon, 1) >= 3
                            mask = poly2mask(obj.curPolygon(:, 2), obj.curPolygon(:, 1), obj.imageSize(1), obj.imageSize(2));
                            [ys, xs] = find(mask);
                            inds = sub2ind(obj.imageSize(1:2), ys, xs);
                            obj.handlePolygon.CData(inds) = labelIdx; %#ok<PROPLC>
                        end
                        
%                         % Draw new polygon marker
%                         markerSize = 3;
%                         regionMapInds = obj.circleInds(pos, markerSize, obj.imageSize);
%                         obj.handlePolygon.CData(regionMapInds) = labelIdx; %#ok<PROPLC>
                        
                        obj.updateAlphaData();
                    end
                else
                    % (Super-)pixel based drawing
                    
                    if obj.drawStatus == 1
                        labelIdx = obj.labelIdx; %#ok<PROPLC>
                    elseif obj.drawStatus == 2
                        labelIdx = obj.cls_unprocessed; %#ok<PROPLC>
                    end
                    
                    if strcmp(obj.drawMode, 'superpixelDraw')
                        % Draw current circle on pixels or superpixels
                        regionMapInds = obj.circleInds(pos, obj.drawSize, obj.imageSize);
                        
                        % Find selected superpixel and create its mask
                        spInds = unique(obj.regionMap(regionMapInds));
                        [selY, selX] = find(ismember(obj.regionMap, spInds));
                        inds = sub2ind(obj.imageSize(1:2), selY, selX);
                        
                        
                        % Set update flag
                        updatedPixels = true;
                    else
                        error('Error: Unknown drawMode: %s', obj.drawMode);
                    end
                end
                
                if updatedPixels
                    % Update pixels and save previous state
                    indsIsOverwrite = (labelIdx == obj.cls_unprocessed | obj.drawOverwrite ...
                        | obj.handleLabelMap.CData(inds) == obj.cls_unprocessed) ...
                        & obj.handleLabelMap.CData(inds) ~= obj.cls_things; %#ok<PROPLC>
                    inds = inds(indsIsOverwrite);
                    obj.labelMapUndo = obj.handleLabelMap.CData;
                    obj.handleLabelMap.CData(inds) = labelIdx; %#ok<PROPLC>
                    
                    % Update history of when which pixels was changed
                    curDrawTime = obj.timeImagePrevious + toc(obj.timerImage);
                    obj.timeMap(inds) = curDrawTime;
                    if ~isempty(obj.lastDrawTime)
                        obj.timeDiffMap(inds) = curDrawTime - obj.lastDrawTime;
                    end
                    obj.drawSizeMap(inds) = obj.drawSize;
                    obj.lastDrawTime = curDrawTime;
                    
                    % Update drawing timer
                    if isempty(obj.timerImageDraw)
                        obj.timerImageDraw = tic;
                    else
                        obj.timeImageDraw = obj.timeImageDrawPrevious + toc(obj.timerImageDraw);
                    end
                    
                    % Update alpha data
                    obj.updateAlphaData();
                end
            end
        end
        
        function[inds] = squareInds(~, center, drawSize, imageSize)
            % Square indices
            selY = max(1, center(1)-drawSize) : min(center(1)+drawSize, imageSize(1));
            selX = max(1, center(2)-drawSize) : min(center(2)+drawSize, imageSize(2));
            [selX, selY] = meshgrid(selX, selY);
            inds = sub2ind(imageSize, selY, selX);
        end
        
        function[inds] = circleInds(~, center, drawSize, imageSize)
            % Circle indices
            % Slightly modified to remove the one odd pixel that often
            % occurs along the horizontal or vertical through the center.
            
            xs = center(2)-drawSize : center(2)+drawSize;
            ys = center(1)-drawSize : center(1)+drawSize;
            [XS, YS] = meshgrid(xs, ys);
            dists = sqrt((XS - center(2)) .^ 2 + (YS - center(1)) .^ 2);
            valid = dists <= drawSize - 0.1 & XS >= 1 & XS <= imageSize(2) & YS >= 1 & YS <= imageSize(1);
            selX = XS(valid);
            selY = YS(valid);
            inds = sub2ind(imageSize, selY, selX);
        end
        
        function updateAlphaData(obj)
            set(obj.handleLabelMap, 'AlphaData', obj.labelMapTransparency * double(obj.handleLabelMap.CData ~= obj.cls_unprocessed));
            set(obj.handleBoundary, 'AlphaData', obj.boundaryTransparency * obj.regionBoundaries);
            set(obj.handlePolygon,  'AlphaData', obj.labelMapTransparency * double(obj.handlePolygon.CData ~= obj.cls_unprocessed));
        end
        
        function figMouseMove(obj, ~, ~)
            % Update timer in figure title
            obj.updateTitle();
            
            imPoint = round(get(obj.ax, 'CurrentPoint'));
            imPoint = [imPoint(1, 2), imPoint(1, 1)];
            
            if 1 <= imPoint(1) && imPoint(1) <= obj.imageSize(1) && ...
                    1 <= imPoint(2) && imPoint(2) <= obj.imageSize(2)
                obj.drawPos(imPoint);
            end
        end
        
        function updateTitle(obj)
            set(obj.figMain, 'Name', sprintf('CocoStuffAnnotator v%s - %s - %s (%d / %d) - %.1fs', obj.toolVersion, obj.userName, obj.imageName, obj.imageIdx, numel(obj.imageList), obj.timeImageDraw));
        end
        
        function figResize(obj, ~, ~)
            yEnd   = 0.9;
            yStart = 0.0;
            ySize = yEnd - yStart;
            
            set(obj.ax, 'Units', 'Norm', 'Position', [0.0, yStart, 1, ySize]);
        end
        
        function figKeyPress(obj, ~, event)
            if strcmp(event.EventName, 'KeyPress')
                if isempty(event.Character)
                    % Do nothing
                elseif strcmp(event.Character, 'q')
                    % Button label hierarchy
                    obj.buttonLabelHierarchyClick();
                elseif strcmp(event.Character, '1')
                    % Unlabeled class
                    obj.setLabelIdx(obj.cls_unlabeled);
                elseif strcmp(event.Character, '+')
                    obj.ui.popupPointSize.Value = min(obj.ui.popupPointSize.Value + 1, numel(obj.ui.popupPointSize.String));
                    obj.drawSize = str2double(obj.ui.popupPointSize.String{obj.ui.popupPointSize.Value});
                elseif strcmp(event.Character, '-')
                    obj.ui.popupPointSize.Value = max(obj.ui.popupPointSize.Value - 1, 1);
                    obj.drawSize = str2double(obj.ui.popupPointSize.String{obj.ui.popupPointSize.Value});
                end
            end
        end
        
        function figScrollWheel(obj, ~, event)
            val = obj.ui.popupPointSize.Value - event.VerticalScrollCount;
            val = min(val, numel(obj.ui.popupPointSize.String));
            val = max(val, 1);
            obj.ui.popupPointSize.Value = val;
            obj.drawSize = str2double(obj.ui.popupPointSize.String{obj.ui.popupPointSize.Value});
        end
        
        %This Callback is called when the object is deleted
        function delete(obj)
            if ishandle(obj.figMain)
                close(obj.figMain)
            end
        end
        
        %If someone closes the figure than everything will be deleted !
        function onclose(obj, src, event) %#ok<INUSD>
            
            % Close other windows
            if ishandle(obj.figLabelHierarchy)
                close(obj.figLabelHierarchy);
            end
            
            delete(src)
            delete(obj)
        end
    end
end