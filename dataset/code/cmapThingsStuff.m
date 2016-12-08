function[cmap] = cmapThingsStuff()
% [cmap] = cmapThingsStuff()
%
% Returns the color map for stuff and thing labels in CocoStuff.
%
% Copyright by Holger Caesar, 2016

% Get stuff and thing color
stuffColors = cmapStuff();
thingColors = cmapThings();

% Remove duplicate backgrund
stuffColors(1, :) = [];
thingColors(1, :) = [];

% Combine unlabeled (black), things and stuff
cmap = [0, 0, 0; thingColors; stuffColors];
end

function[cmap] = cmapStuff()
% [cmap] = cmapStuff()
%
% Returns the color map for stuff labels in CocoStuff.
%
% Copyright by Holger Caesar, 2016

% Settings
stuffCount = 91;

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

function[cmap] = cmapThings()
% [cmap] = cmapThings()
%
% Returns the color map for thing labels in CocoStuff.
%
% Copyright by Holger Caesar, 2016

% Settings
thingCount = 80;

thingColors = jet(thingCount);

% Shuffle colors and reset random number generator
backup = rng;
rng(42);
thingColors = thingColors(randperm(thingCount), :);
rng(backup);

cmap = [0, 0, 0; thingColors];
end