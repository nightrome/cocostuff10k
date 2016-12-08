function seg = segment_from_windows(image,initWindows,constrainToInit,maxIterations)
% Segments the image using windows to initialize and contrain the segmentation.
%
% arguments:
%   image = rgb uint8 image
%   init_windows = windows (N-by-4 matrix, N>0, each line is [xmin ymin xmax ymax])
%   constrain_to_windows = true/false
%   maxIterations = maximum number of iterations for GrabCut
%
% returns:
%   seg = segmentation as logical image

% require at least one window
assert(size(initWindows,1)>0);

initMask = maskFromWindows(size(image,1),size(image,2),initWindows);
seg = segment_from_hardmask(image,initMask,constrainToInit,maxIterations);
