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