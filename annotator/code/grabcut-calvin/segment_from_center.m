function seg = segment_from_center(image,centerInitFrac,constrainToInit,maxIterations)
% Segments the image using a centered window to initialize Grabcut.
%
% arguments:
%   image = rgb uint8 image, or cell of ~
%   centerInit = fraction of image to use as initialization (centered window)
%   maxIterations = maximum number of iterations for GrabCut
%
% returns:
%   seg = segmentation as logical image, or cell of ~, same size as image(s)

h = size(image,1);
w = size(image,2);

centerInitFrac = sqrt(centerInitFrac); % convert fraction of surface to fraction of axis
initWindow = windowFromCenter(h,w,centerInitFrac);

seg = segment_from_windows(image,initWindow,constrainToInit,maxIterations);
