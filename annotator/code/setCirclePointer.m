function setCirclePointer(fig)
% setCirclePointer(fig)
%
% Sets the cursor/pointer in the current figure to be a 16x16 circle with a point in the middle.
% We center the circle around floor(iconSize/2) for simplicity.
%
% Copyright by Holger Caesar, 2016

% Settings
iconSize = 16;
radius = 6;
thickness = 1;

% Define center
midSize = floor(iconSize / 2);
center = [midSize, midSize];

% Create circle
icon = nan(iconSize, iconSize);
xs = 1:iconSize;
ys = 1:iconSize;
[XS, YS] = meshgrid(xs, ys);
dists = abs(sqrt((XS - center(2)) .^ 2 + (YS - center(1)) .^ 2) - radius);
icon(dists <= thickness) = 1;

% Color center
icon(center(1), center(2)) = 1;

% Set in figure
set(fig, 'Pointer', 'custom', 'PointerShapeCData', icon, 'PointerShapeHotSpot', center);