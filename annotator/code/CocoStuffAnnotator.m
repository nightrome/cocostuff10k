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
        regionName = 'slico-1000' % slico-1000 or pixels
        toolVersion = '0.8'
        showThings = true
        
        % Main figure
        figMain
        containerButtons
        containerOptions
        containerStatus
        ax
        ui
        handleImage
        handleLabelMap
        handleOverlay
        
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
        drawStatus = 0; % 0: nothing, 1: left mouse, 2: right mouse
        drawMode = 'superpixelDraw';
        drawOverwrite = false;
        drawSizes = [1, 2, 5, 10, 15, 20, 30, 50, 100]';
        drawSize = 1;
        drawColors
        drawColor
        drawNow = false;
        labelMapTransparency = 0.6;
        overlayTransparency = 0.2;
        timerTotal
        timerImage
        timeImagePrevious
        
        % Administrative
        imageList
        labelNames
        datasetStuff
        dataFolder
        regionFolder
        thingFolder
        maskFolder
        userName
        
        % Image-specific
        imageIdx
        imageSize
        image
        imageName
        regionMap
        regionBoundaries
        labelMapUndo
    end
    
    methods
        % Constructor
        function obj = CocoStuffAnnotator(varargin)
            
            % Initial settings
            p = inputParser;
            addParameter(p, 'datasetStuff', CocoStuffAnnotatorDataset());
            addParameter(p, 'imageIdx', 1);
            parse(p, varargin{:});
            
            % Set as global options
            obj.datasetStuff = p.Results.datasetStuff;
            obj.imageIdx = p.Results.imageIdx;
            
            % Set timer
            obj.timerTotal = tic;
            
            % Setup folders
            codeFolder = fileparts(mfilename('fullpath'));
            obj.dataFolder = fullfile(fileparts(codeFolder), 'data');
            
            % Read user name
            userNamePath = fullfile(obj.dataFolder, 'input', 'user.txt');
            userName = readLinesToCell(userNamePath);
            assert(numel(userName) == 1 && ~isempty(userName));
            obj.userName = userName{1};
            
            % Setup user folders
            obj.regionFolder  = fullfile(obj.dataFolder, 'input',  'regions', obj.regionName);
            obj.thingFolder  = fullfile(obj.dataFolder, 'input',  'things');
            obj.maskFolder = fullfile(obj.dataFolder, 'output', 'annotations', obj.userName);
            
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
            
            obj.ui.sliderOverlayTransparency = uicontrol(obj.containerOptions, ...
                'Style', 'slider', ...
                'Min', 0, 'Max', 100, 'Value', 100 * obj.overlayTransparency, ...
                'Callback', @(handle, event) sliderOverlayTransparencyChange(obj, handle, event));
            
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
            obj.handleOverlay = image([]);
            hold off;
            
            % Specify the colors for each label in the labelMap
            colormap(obj.ax, obj.drawColors);
            
            % Set axis units
            obj.ax.Units = 'pixels';
            
            % Image event callbacks
            set(obj.handleLabelMap, 'ButtonDownFcn', @(handle, event) handleClickDown(obj, handle, event));
            set(obj.handleOverlay, 'ButtonDownFcn', @(handle, event) handleClickDown(obj, handle, event));
            
            % Figure event callbacks
            set(obj.figMain, 'WindowButtonMotionFcn', @(handle, event) figMouseMove(obj, handle, event));
            set(obj.figMain, 'WindowButtonUpFcn', @(handle, event) figClickUp(obj, handle, event));
            set(obj.figMain, 'ResizeFcn', @(handle, event) figResize(obj, handle, event));
            set(obj.figMain, 'KeyPressFcn', @(handle, event) figKeyPress(obj, handle, event));
            set(obj.figMain, 'WindowScrollWheelFcn', @(handle, event) figScrollWheel(obj, handle, event));
            
            % Set fancy mouse pointer
            setCirclePointer(obj.figMain);
            
            % Load image
            obj.loadImage();
        end
        
        function loadImage(obj)
            % Reads the current imageIdx
            % Resets all image-specific settings and loads a new image
            
            % Set timer
            obj.timerImage = tic;
            
            % Load image
            obj.imageName = obj.imageList{obj.imageIdx};
            obj.image     = obj.datasetStuff.getImage(obj.imageName);
            obj.imageSize = size(obj.image);
            
            % Load regions from file
            regionPath = fullfile(obj.regionFolder, sprintf('%s.mat', obj.imageName));
            if exist(regionPath, 'file')
                regionStruct = load(regionPath, 'regionMap', 'regionBoundaries');
                obj.regionMap = regionStruct.regionMap;
                obj.regionBoundaries = regionStruct.regionBoundaries;
            else
                error('Error: Cannot find region file: %s\n', regionPath);
            end
            
            % Load things from file if specified
            thingPath = fullfile(obj.thingFolder, sprintf('%s.mat', obj.imageName));
            if obj.showThings && exist(thingPath, 'file')
                % Load things
                thingStruct = load(thingPath, 'labelMapThings');
                labelMapThings = thingStruct.labelMapThings;
            elseif obj.showThings
                % Load dummy things and print warning
                labelMapThings = false(size(obj.regionMap));
                fprintf('Warning: Cannot find things file: %s\n', thingPath);
            else
                % Load dummy things and ignore
                labelMapThings = false(size(obj.regionMap));
            end
            
            % Load annotation if it already exists
            maskPath = fullfile(obj.maskFolder, sprintf('mask-%s.mat', obj.imageName));
            if exist(maskPath, 'file')
                fprintf('Loading existing annotation mask %s...\n', maskPath);
                maskStruct = load(maskPath, 'labelMap', 'timeImage', 'labelNames');
                labelMap = maskStruct.labelMap;
                obj.timeImagePrevious = maskStruct.timeImage;
                
                % Make sure labels haven't changed since last time
                savedLabelNames = maskStruct.labelNames;
                assert(isequal(savedLabelNames, obj.labelNames));
                
                assert(obj.imageSize(1) == size(labelMap, 1) && obj.imageSize(2) == size(labelMap, 2) && size(labelMap, 3) == 1);
            else
                fprintf('Creating new annotation mask %s...\n', maskPath);
                labelMap = ones(obj.imageSize(1), obj.imageSize(2));
                labelMap(labelMapThings) = obj.cls_things;
                obj.timeImagePrevious = 0;
            end
            assert(min(labelMap(:)) >= 1);
            
            % Show images
            obj.handleImage.CData = obj.image;
            obj.handleLabelMap.CData = labelMap;
            
            % Set undo data
            obj.labelMapUndo = obj.handleLabelMap.CData;
            
            % Update alpha data
            obj.updateAlphaData();
            
            % Show boundaries
            overlayIm = zeros(obj.imageSize);
            overlayIm(:, :, 1) = 1;
            obj.handleOverlay.CData = overlayIm;
            
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
            labelIdx = findClosestLabelInTree(pos, obj.ysLabelHierarchyIn, obj.xsLabelHierarchyIn, obj.categoriesLabelHierarchyIn); %#ok<PROPLC>
            
            % Set globally
            obj.setLabelIdx(labelIdx); %#ok<PROPLC>
        end
        
        function pickLabelOutClick(obj, ~, event)
            % Find closest label outdoors
            pos = [event.IntersectionPoint(2), event.IntersectionPoint(1)];
            labelIdx = findClosestLabelInTree(pos, obj.ysLabelHierarchyOut, obj.xsLabelHierarchyOut, obj.categoriesLabelHierarchyOut); %#ok<PROPLC>
            
            % Set globally
            obj.setLabelIdx(labelIdx); %#ok<PROPLC>
        end
        
        function[labelIdx] = findClosestLabelInTree(pos, ys, xs, cats)
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
        
        function saveMask(obj)
            % Check if anything was annotated
            labelMap = obj.handleLabelMap.CData;
            maskPath = fullfile(obj.maskFolder, sprintf('mask-%s.mat', obj.imageName));
            if all(labelMap(:) == obj.cls_unprocessed)
                fprintf('Not saving annotation for unedited image %s...\n', maskPath);
                return;
            end
            
            % Create folder
            if ~exist(obj.maskFolder, 'dir')
                mkdir(obj.maskFolder)
            end
            
            % Save mask
            fprintf('Saving annotation mask to %s...\n', maskPath);
            saveStruct.imageIdx = obj.imageIdx;
            saveStruct.imageSize = obj.imageSize;
            saveStruct.imageName = obj.imageName;
            saveStruct.labelMap = labelMap;
            saveStruct.labelNames = obj.labelNames;
            saveStruct.timeTotal = toc(obj.timerTotal);
            saveStruct.timeImage = obj.timeImagePrevious + toc(obj.timerImage);
            saveStruct.userName = obj.userName; %#ok<STRNU>
            save(maskPath, '-struct', 'saveStruct', '-v7.3');
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
            
            % Save current mask
            obj.saveMask();
            
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
            
            % Save current mask
            obj.saveMask();
            
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
            
            % Save current mask
            obj.saveMask();
            
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
        
        function sliderOverlayTransparencyChange(obj, ~, event)
            obj.overlayTransparency = event.Source.Value / 100;
            obj.updateAlphaData();
        end
        
        function handleClickDown(obj, handle, event) %#ok<INUSL>
            pos = round([event.IntersectionPoint(2), event.IntersectionPoint(1)]);
            if event.Button == 1
                % Left click (set label)
                obj.drawStatus = 1;
            elseif event.Button == 3
                % Right click (set unprocessed)
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
            if obj.drawStatus ~= 0
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
                    obj.drawMode = 'superpixelDraw';
                else
                    if obj.drawStatus == 1
                        labelIdx = obj.labelIdx; %#ok<PROPLC>
                    elseif obj.drawStatus == 2
                        labelIdx = obj.cls_unprocessed; %#ok<PROPLC>
                    end
                    
                    % Draw current circle on pixels or superpixels
                    if false
                        % Square
                        selY = max(1, pos(1)-obj.drawSize) : min(pos(1)+obj.drawSize, obj.imageSize(1)); %#ok<UNRCH>
                        selX = max(1, pos(2)-obj.drawSize) : min(pos(2)+obj.drawSize, obj.imageSize(2));
                        [selX, selY] = meshgrid(selX, selY);
                    else
                        % Circle
                        xs = pos(2)-obj.drawSize : pos(2)+obj.drawSize;
                        ys = pos(1)-obj.drawSize : pos(1)+obj.drawSize;
                        [XS, YS] = meshgrid(xs, ys);
                        dists = sqrt((XS - pos(2)) .^ 2 + (YS - pos(1)) .^ 2);
                        valid = dists <= obj.drawSize - 0.1 & XS >= 1 & XS <= obj.imageSize(2) & YS >= 1 & YS <= obj.imageSize(1);
                        selX = XS(valid);
                        selY = YS(valid);
                    end
                    
                    if strcmp(obj.drawMode, 'superpixelDraw')
                        % Find selected superpixel and create its mask
                        regionMapInds = sub2ind(size(obj.regionMap), selY, selX);
                        spInds = unique(obj.regionMap(regionMapInds));
                        mask = ismember(obj.regionMap, spInds);
                        [selY, selX] = find(mask);
                        inds = sub2ind(obj.imageSize(1:2), selY, selX);
                        indsIsOverwrite = (labelIdx == obj.cls_unprocessed | obj.drawOverwrite | obj.handleLabelMap.CData(inds) == obj.cls_unprocessed) ...
                            & obj.handleLabelMap.CData(inds) ~= obj.cls_things; %#ok<PROPLC>
                        obj.labelMapUndo = obj.handleLabelMap.CData;
                        obj.handleLabelMap.CData(inds(indsIsOverwrite)) = labelIdx; %#ok<PROPLC>
                    end
                    
                    % Update alpha data
                    obj.updateAlphaData();
                end
            end
        end
        
        function updateAlphaData(obj)
            set(obj.handleLabelMap, 'AlphaData', obj.labelMapTransparency * double(obj.handleLabelMap.CData ~= obj.cls_unprocessed));
            set(obj.handleOverlay, 'AlphaData', obj.overlayTransparency * obj.regionBoundaries);
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
            
            timeImage = obj.timeImagePrevious;
            if ~isempty(obj.timerImage)
                timeImage = timeImage + toc(obj.timerImage);
            end
            set(obj.figMain, 'Name', sprintf('CocoStuffAnnotator v%s - %s - %s (%d / %d) - %.1fs', obj.toolVersion, obj.userName, obj.imageName, obj.imageIdx, numel(obj.imageList), timeImage));
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
                elseif strcmp(event.Character, 'w')
                    % Button pick label
                    obj.buttonPickLabelClick();
                elseif strcmp(event.Character, 'e')
                    % Button clear label
                    obj.buttonClearLabelClick();
                elseif strcmp(event.Character, 'r')
                    % Button prev image
                    obj.buttonPrevImageClick();
                elseif strcmp(event.Character, 't')
                    % Button jump image
                    obj.buttonJumpImageClick();
                elseif strcmp(event.Character, 'y')
                    % Button next image
                    obj.buttonNextImageClick();
                elseif strcmp(event.Character, '1')
                    % Unlabeled class
                    obj.setLabelIdx(2);
                elseif strcmp(event.Character, '2')
                    % Things class
                    obj.setLabelIdx(4);
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