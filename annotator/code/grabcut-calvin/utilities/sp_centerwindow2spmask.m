function stat = sp_centerwindow2spmask(labels,frac)
% stat = sp_centerwindow2spmask(superpixels,frac)
%
% Compute a superpixel soft mask from a centered window using frac of image
%
% INPUTS:
% superpixels: a superpixel segmentation
% frac: fraction of image to use
%

labels = double(labels);

C = max(labels(:));
stat.n    = zeros(C,1,'uint16');
stat.mean = zeros(C,1);
%stat.median = zeros(C,1);
%stat.var  = zeros(C,1);

centerInitFrac = sqrt(frac); % convert fraction of surface to fraction of axis
h = size(labels,1);
w = size(labels,2);
pixmask = false(h,w);
yc = (h+1)/2;  xc = (w+1)/2;
yr = round(yc-centerInitFrac*h/2):round(yc+centerInitFrac*h/2);
xr = round(xc-centerInitFrac*w/2):round(xc+centerInitFrac*w/2);
%fprintf('init window is %dx%d\n',numel(yr),numel(xr));
pixmask(yr,xr) = true;

data = double(pixmask(:));
for i=1:C,
    idx = labels==i;
    x=data(idx,:);
    stat.n(i) = size(x,1);
    stat.mean(i) = mean(x);
    stat.median(i) = median(x);
    stat.var(i) = sum((x-stat.mean(i)).^2);
end

end
