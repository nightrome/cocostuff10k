function [stat,pixmask] = sp_window2spmask(labels,windows)
% stat = sp_centerwindow2spmask(superpixels,frac)
%
% Compute a superpixel soft mask from a centered window using frac of image
%
% INPUTS:
% superpixels: a superpixel segmentation
% frac: fraction of image to use
%

labels = double(labels);
[h,w] = size(labels);

pixmask = maskFromWindows(h,w,windows);

if h*w>10000,
    margin=10;
else
    margin=5;
end

pixmask(1:margin,:) = false;
pixmask(:,1:margin) = false;
pixmask(:,end-margin+1:end) = false;
pixmask(end-margin+1:end,:) = false;

stat = sp_maskstat(pixmask,labels);

end
