classdef CocoStuffAnnotatorDataset
    % CocoStuffAnnotatorDataset
    %
    % Semantic segmentation dataset for stuff classes in COCO
    %
    % Copyright by Holger Caesar, 2016
    
    % Properties that are normally in the Dataset class
    properties
        % General settings
        name
        
        % Image settings
        imageExt = '.jpg';
        imageFolder = 'Images';
    end
    
    methods
        function[obj] = CocoStuffAnnotatorDataset()
            % Define dataset
            obj.name = 'CocoStuff';
            obj.imageExt = '.jpg';
        end
        
        function[image] = getImage(obj, imageName, ~)
            % [image] = getImage(obj, imageName, ~)
            
            % Create path
            imageFolderFull = fullfile(cocoStuff_root(), 'annotator', 'data', 'input', 'images');
            imagePath = fullfile(imageFolderFull, [imageName, obj.imageExt]);
            
            % Read in image and convert to double
            image = im2double(imread(imagePath));
            
            % Convert grayscale to rgb
            if size(image, 3) == 1
                image = cat(3, image, image, image);
            end
        end
        
        function[labelNames, labelCount] = getLabelNames(~)
            % [labelNames, labelCount] = getLabelNames(~)
            %
            % Get a cell of strings that specify the names of each label.
            
            thingNames = CocoStuffClasses.getLabelNamesThings();
            stuffNames = CocoStuffClasses.getLabelNamesStuff();
            
            labelNames = ['unlabeled'; thingNames; stuffNames];
            labelCount = numel(labelNames);
        end
    end
end