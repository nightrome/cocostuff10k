function[cmap] = cmapStuff()
% [cmap] = cmapStuff()
%
% Returns the color map for stuff labels in CocoStuff.
%
% Copyright by Holger Caesar, 2016

% Settings
stuffCount = CocoStuffClasses.stuffCount;

% Get jet colormap and modify third dimension of hsv value
stuffColors = jet(stuffCount);
stuffColors = rgb2hsv(stuffColors);
stuffColors(:, 3) = 0.5 * stuffColors(:, 3);

stuffColors = hsv2rgb(stuffColors);

% Shuffle colors and reset random number generator
backup = rng;
rng(42);
stuffColors = stuffColors(randperm(stuffCount), :);
rng(backup);

cmap = [0, 0, 0; stuffColors];
end